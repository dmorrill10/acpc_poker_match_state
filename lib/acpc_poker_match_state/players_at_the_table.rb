# @todo Remove this
require 'awesome_print'

require 'dmorrill10-utils'
require 'acpc_poker_types'

require File.expand_path('../match_state_transition', __FILE__)

class PlayersAtTheTable

  exceptions :player_acted_before_sitting_at_table,
    :no_players_to_seat, :users_seat_out_of_bounds,
    :multiple_players_have_the_same_seat

  attr_reader :players

  # @return [Array<Array<Integer>>] The sequence of seats that acted,
  #  separated by round.
  attr_reader :player_acting_sequence

  attr_reader :transition

  attr_reader :number_of_hands

  attr_reader :game_def

  attr_reader :users_seat

  attr_reader :min_wager

  attr_reader :player_who_acted_last

  alias_new :seat_players

  # @param [GameDefinition] game_def The game definition for the
  #  match these players are playing.
  # @param [Array<String>] player_names The names of the players to seat at the table,
  #  ordered by seat.
  # @param [Integer] users_seat The user's seat at the table.
  #  players are joining.
  # @param [Integer] number_of_hands The number of hands in this match.
  def initialize(game_def, player_names, users_seat, number_of_hands)
    @players = Player.create_players player_names, game_def

    @users_seat = if users_seat.seat_in_bounds?(number_of_players) && @players.any?{|player| player.seat == users_seat}
      users_seat
    else
      raise UsersSeatOutOfBounds, users_seat
    end

    @game_def = game_def
    @min_wager = @game_def.min_wagers.first

    @transition = MatchStateTransition.new

    @player_acting_sequence = [[]]

    @number_of_hands = number_of_hands
  end

  def blinds
    @game_def.blinds
  end

  # @return [Integer] The number of players seated at the table.
  def number_of_players() @players.length end

  # @param [MatchState] match_state The next match state.
  def update!(match_state)
    @transition.set_next_state! match_state

    if @transition.initial_state?
      start_new_hand!
    else
      @player_acting_sequence.last << next_player_to_act(@transition.last_state).seat

      update_state_of_players!

      @player_acting_sequence << [] if @transition.new_round?
    end
    self
  end

  def next_player_to_act(state=@transition.next_state)
    return nil unless state && !hand_ended? && !active_players.empty?
      
    reference_position = if state.number_of_actions_this_round > 0
      position_relative_to_dealer player_who_acted_last
    else
      @game_def.first_player_positions[state.round] - 1
    end

    number_of_players.times.inject(nil) do |player_who_might_act, i|
      position_relative_to_dealer_to_act = (reference_position + i + 1) % number_of_players
      player_who_might_act = active_players.find do |player|
        position_relative_to_dealer(player) == position_relative_to_dealer_to_act
      end
      if player_who_might_act then break player_who_might_act else nil end
    end
  end

  def player_who_acted_last
    unless round_in_which_last_action_taken
      nil
    else
      @players.find do |player|
        player.seat == @player_acting_sequence[round_in_which_last_action_taken].last
      end
    end
  end

  def opponents
    @players.select { |player| player.seat != @users_seat }
  end

  def user_player
    @players.find { |player| @users_seat == player.seat }
  end

  # @return [Array<Player>] The players who are active.
  def active_players
    @players.select { |player| player.active? }
  end

  #@return [Array<Player>] The players who have not folded.
  def non_folded_players
    @players.select { |player| !player.folded? }
  end

  # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
  def hand_ended?
    less_than_two_non_folded_players? || reached_showdown?
  end

  # @return [Boolean] +true+ if the match has ended, +false+ otherwise.
  def match_ended?
    hand_ended? && last_hand?
  end

  def less_than_two_non_folded_players?
    non_folded_players.length < 2
  end

  def reached_showdown?
    opponents_cards_visible?
  end

  # @return [Boolean] +true+ if any opponents cards are visible, +false+ otherwise.
  def opponents_cards_visible?
    opponents.any? { |player| player.hole_cards && !player.hole_cards.empty? }
  end

  # @return [Player] The player with the dealer button.
  def player_with_dealer_button
    return nil unless @transition.next_state
    @players.find { |player| position_relative_to_dealer(player) == number_of_players - 1}
  end

  # @return [Hash<Player, #to_i] Relation from player to the blind that player paid.
  def player_blind_relation
    return nil unless @transition.next_state

    @players.inject({}) do |relation, player|
      relation[player] = blinds[position_relative_to_dealer(player)]
      relation
    end
  end

  # @return [String] player acting sequence as a string.
  def player_acting_sequence_string
    (@player_acting_sequence.map { |per_round| per_round.join('') }).join('/')
  end

  def betting_sequence_string
    (betting_sequence.map do |per_round|
       (per_round.map{|action| action.to_acpc}).join('')
    end).join('/')
  end

  def betting_sequence
    sequence = [[]]
    return sequence unless @transition.next_state

    @player_acting_sequence.each_with_index do |per_round, i|
      actions_taken_this_round = {}

      unless per_round.empty?
        @players.each do |player|
          # Skip if player has folded and a round after the fold is being checked
          next if i >= player.actions_taken_this_hand.length

          actions_taken_this_round[player.seat] = player.actions_taken_this_hand[i].dup
        end
      end

      per_round.each do |seat|
        sequence.last << actions_taken_this_round[seat].shift
      end
      sequence << [] if (@transition.next_state.round+1) > sequence.length
    end
    sequence
  end

  # @return [Boolean] +true+ if it is the user's turn to act, +false+ otherwise.
  def users_turn_to_act?
    if next_player_to_act
      next_player_to_act.seat == @users_seat
    else
      false
    end
  end

  # @return [Array<ChipStack>] Player stacks.
  def chip_stacks
    @players.map { |player| player.chip_stack }
  end

  # return [Array<Integer>] Each player's current chip balance.
  def chip_balances
    @players.map { |player| player.chip_balance }
  end

  # return [Array<Array<Integer>>] Each player's current chip contribution organized by round.
  def chip_contributions
    @players.map { |player| player.chip_contributions }
  end

  # @param [Integer] player The player of which the position relative to the
  #  dealer is desired.
  # @return [Integer] The position relative to the user of the given player,
  #  +player+, indexed such that the player immediately to the left of the
  #  dealer has a +position_relative_to_dealer+ of zero.
  # @example The player immediately to the left of the user has
  #     +position_relative_to_user+ == 0
  # @example The user has
  #     +position_relative_to_user+ == +number_of_players+ - 1
  # @raise (see Integer#position_relative_to)
  def position_relative_to_user(player)
    player.seat.position_relative_to user_player.seat, number_of_players
  end

  # @param [Integer] player The player of which the position relative to the
  #  dealer is desired.
  # @return [Integer] The position relative to the dealer of the given player,
  #  +player+, indexed such that the player immediately to to the left of the
  #  dealer has a +position_relative_to_dealer+ of zero.
  # @raise (see Integer#seat_from_relative_position)
  # @raise (see Integer#position_relative_to)
  def position_relative_to_dealer(player)
    seat_of_dealer = @users_seat.seat_from_relative_position(
    users_position_relative_to_dealer, number_of_players)

    player.seat.position_relative_to seat_of_dealer, number_of_players
  end

  def amount_to_call(player)
    @players.map do |p|
      p.chip_contributions.sum
    end.max - player.chip_contributions.sum
  end

  def cost_of_action(player, action, round=round_in_which_last_action_taken)
    ChipStack.new(
      if action.to_sym == :call
        amount_to_call player
      elsif action.to_sym == :bet || action.to_sym == :raise
        if action.modifier
          action.modifier - player.chip_contributions.sum
        else
          @game_def.min_wagers[round] + amount_to_call(player)
        end
      else
        0
      end
    )
  end

  # @return [Set] The set of legal actions for the currently acting player.
  def legal_actions
    list_of_action_symbols = if next_player_to_act.nil?
      []
    elsif player_sees_wager?
      [:call, :fold, :raise]
    elsif chips_contributed_to_pot_this_round?
      [:check, :raise]
    else
      [:check, :bet]
    end

    list_of_action_symbols.inject(Set.new) do |set, action_symbol|
      set << PokerAction.new(action_symbol)
    end
  end

  # @return [Boolean] +true+ if the current hand is the last in the match.
  def last_hand?
    # @todo make sure +@match_state.hand_number+ is not greater than @number_of_hands
    return false unless @transition.next_state

    @transition.next_state.hand_number == @number_of_hands - 1
  end

  private

  def player_contributed_to_pot_this_round?(player=next_player_to_act)
    player.chip_contributions.last > 0
  end

  # @todo Change MST#next_state to current_state
  def chips_contributed_to_pot_this_round?(round=@transition.next_state.round)
    chip_contributions.inject(0) do |both_players_contributions, contributions|
      both_players_contributions += contributions[round].to_i
    end > 0
  end

  def player_sees_wager?(player=next_player_to_act)
    amount_to_call(player) > 0
  end

  def users_position_relative_to_dealer() @transition.next_state.position_relative_to_dealer end

  # @todo move to MatchState
  def round_in_which_last_action_taken(state=@transition.next_state)
    unless state && state.number_of_actions_this_hand > 0
      nil
    else
      if state.number_of_actions_this_round < 1
        state.round - 1
      else
        state.round
      end
    end
  end

  def start_new_hand!
    @player_acting_sequence = [[]]

    @players.each do |player|
      player.start_new_hand!(
        blinds[position_relative_to_dealer(player)],
        @game_def.chip_stacks[position_relative_to_dealer(player)], # @todo if playing Doyle's game
        @transition.next_state.list_of_hole_card_hands[position_relative_to_dealer(player)]
      )
    end

    set_min_wager!
  end

  def assign_hole_cards_to_players!
    @players.each do |player|
      player.assign_cards! @transition.next_state.list_of_hole_card_hands[position_relative_to_dealer(player)]
    end
  end

  def update_state_of_players!
    assign_hole_cards_to_players!

    action_with_context = PokerAction.new(
      @transition.next_state.last_action.to_acpc, {
        amount_to_put_in_pot: cost_of_action(
          player_who_acted_last,
          @transition.next_state.last_action
        ),
        # @todo Change the name and semantics of this key here to chips_has_contributed
        acting_player_sees_wager: chips_contributed_to_pot_this_round?(@transition.next_state.round_in_which_last_action_taken)
      }
    )
    player_who_acted_last.take_action! action_with_context

    # @todo I'm concerned that this doesn't work properly in multiplayer...
    @min_wager = ChipStack.new [@min_wager.to_i, action_with_context.amount_to_put_in_pot.to_i].max

    if @transition.new_round?
      active_players.each { |player| player.start_new_round! }
      set_min_wager!
    end

    if hand_ended?
      distribute_chips! @transition.next_state.board_cards
    end
  end

  # Distribute chips to all winning players
  # @param [BoardCards] board_cards The community board cards.
  def distribute_chips!(board_cards)
    raise NoChipsToDistribute unless pot > 0
    raise NoPlayersToTakeChips unless non_folded_players.length > 0

    if 1 == non_folded_players.length
      non_folded_players.first.take_winnings! pot
    else
      players_and_their_hand_strength = {}
      non_folded_players.each do |player|
        hand_strength = PileOfCards.new(board_cards.flatten + player.hole_cards).to_poker_hand_strength

        players_and_their_hand_strength[player] = hand_strength
      end

      strength_of_strongest_hand = players_and_their_hand_strength.values.max
      winning_players = players_and_their_hand_strength.find_all do |player, hand_strength|
        hand_strength == strength_of_strongest_hand
      end.map { |player_with_hand_strength| player_with_hand_strength.first }

      amount_each_player_wins = (pot/winning_players.length).floor
      winning_players.each do |player|
        player.take_winnings! amount_each_player_wins
      end

      # @todo Keep track of chips remaining in the pot after splitting them if multiplayer
      #@value -= (amount_each_player_wins * winning_players.length).to_i
    end
  end

  # @todo This only works for Doyle's game where there are no side-pots.
  def pot
    chip_contributions.mapped_sum.sum
  end

  def set_min_wager!
    @min_wager = @game_def.min_wagers[@transition.next_state.round]
  end
end

class Array
  def find_out_of_bounds_seat(number_of_players)
    self.find do |position|
      !position.seat_in_bounds?(number_of_players)
    end
  end
  def copy
    inject([]) { |new_array, elem| new_array << elem.copy }
  end
end
