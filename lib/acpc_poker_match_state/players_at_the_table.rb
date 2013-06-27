require 'acpc_poker_types'
require 'acpc_poker_match_state/match_state_transition'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module AcpcPokerMatchState
  class PlayersAtTheTable
    exceptions :player_acted_before_sitting_at_table,
      :no_players_to_seat, :multiple_players_have_the_same_seat

    attr_reader :players

    # @return [Array<Array<Integer>>] The sequence of seats that acted,
    #  separated by round.
    attr_reader :player_acting_sequence

    attr_reader :transition

    attr_reader :number_of_hands

    attr_reader :game_def

    attr_reader :users_seat

    # @return [ChipStack] Minimum wager by.
    attr_reader :min_wager

    attr_reader :player_who_acted_last

    class << self; alias_method(:seat_players, :new) end

    # @param [GameDefinition] game_def The game definition for the
    #  match these players are playing.
    # @param [Array<String>] player_names The names of the players to seat at the table,
    #  ordered by seat.
    # @param [Integer] users_seat The user's seat at the table.
    #  players are joining.
    # @param [Integer] number_of_hands The number of hands in this match.
    def initialize(game_def, player_names, users_seat, number_of_hands)
      @players = AcpcPokerTypes::Player.create_players player_names, game_def

      @users_seat = AcpcPokerTypes::Seat.new(users_seat, player_names.length)

      @game_def = game_def
      @min_wager = game_def.min_wagers.first

      @transition = AcpcPokerMatchState::MatchStateTransition.new

      @player_acting_sequence = [[]]

      @number_of_hands = number_of_hands
    end

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

      @players.length.times.inject(nil) do |player_who_might_act, i|
        position_relative_to_dealer_to_act = (reference_position + i + 1) % @players.length
        player_who_might_act = active_players.find do |player|
          position_relative_to_dealer(player) == position_relative_to_dealer_to_act
        end
        if player_who_might_act then break player_who_might_act else nil end
      end
    end

    def player_who_acted_last
      unless @transition.next_state && @transition.next_state.round_in_which_last_action_taken
        nil
      else
        @players.find do |player|
          player.seat == @player_acting_sequence[@transition.next_state.round_in_which_last_action_taken].last
        end
      end
    end

    def opponents
      @players.select { |player| player.seat != @users_seat }
    end

    def user_player
      @players.find { |player| @users_seat == player.seat }
    end

    # @return [Array<AcpcPokerTypes::Player>] The players who are active.
    def active_players
      @players.select { |player| player.active? }
    end

    #@return [Array<AcpcPokerTypes::Player>] The players who have not folded.
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

    # @return [AcpcPokerTypes::Player] The player with the dealer button.
    def player_with_dealer_button
      return nil unless @transition.next_state
      @players.find { |player| position_relative_to_dealer(player) == @players.length - 1}
    end

    # @return [Hash<AcpcPokerTypes::Player, #to_i] Relation from player to the blind that player paid.
    def player_blind_relation
      return nil unless @transition.next_state

      @players.inject({}) do |relation, player|
        relation[player] = @game_def.blinds[position_relative_to_dealer(player)]
        relation
      end
    end

    # @return [String] player acting sequence as a string.
    def player_acting_sequence_string
      (@player_acting_sequence.map { |per_round| per_round.join('') }).join('/')
    end

    def betting_sequence_string
      (betting_sequence.map do |per_round|
         (per_round.map{|action| action.to_s}).join('')
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

    # @return [Array<AcpcPokerTypes::ChipStack>] AcpcPokerTypes::Player stacks.
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
    #  user has a +position_relative_to_user+ of zero.
    # @example The player immediately to the left of the user has
    #     +position_relative_to_user+ == 0
    # @example The user has
    #     +position_relative_to_user+ == +@players.length+ - 1
    # @raise (see Integer#position_relative_to)
    def position_relative_to_user(player)
      @users_seat.n_seats_away(1).seats_to player.seat
    end

    # @param [Integer] player The player of which the position relative to the
    #  dealer is desired.
    # @return [Integer] The position relative to the dealer of the given player,
    #  +player+, indexed such that the player immediately to to the left of the
    #  dealer has a +position_relative_to_dealer+ of zero.
    # @raise (see Integer#seat_from_relative_position)
    # @raise (see Integer#position_relative_to)
    def position_relative_to_dealer(player)
      seats_from_dealer = (users_position_relative_to_dealer + 1) % @players.length

      dealers_seat = AcpcPokerTypes::Seat.new(
        if @users_seat < seats_from_dealer
          @players.length
        else
          0
        end + @users_seat - seats_from_dealer,
        @players.length
      )

      dealers_seat.n_seats_away(1).seats_to(player.seat)
    end

    def amount_to_call(player = next_player_to_act)
      @players.map do |p|
        p.chip_contributions.inject(:+)
      end.max - player.chip_contributions.inject(:+)
    end

    def cost_of_action(player, action, round=@transition.next_state.round_in_which_last_action_taken)
      AcpcPokerTypes::ChipStack.new(
        if action.action == AcpcPokerTypes::PokerAction::CALL
          amount_to_call player
        elsif action.action == AcpcPokerTypes::PokerAction::BET || action.action == AcpcPokerTypes::PokerAction::RAISE
          if action.modifier
            action.modifier.to_i - player.chip_contributions.inject(:+)
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
      Set.new(
        if next_player_to_act.nil?
          []
        elsif player_sees_wager?
          actions_without_wager = [
            AcpcPokerTypes::PokerAction::CALL,
            AcpcPokerTypes::PokerAction::FOLD
          ]

          if wager_legal?
            actions_without_wager << AcpcPokerTypes::PokerAction::RAISE
          else
            actions_without_wager
          end
        elsif chips_contributed_to_pot_this_round?
          actions_without_wager = [AcpcPokerTypes::PokerAction::CHECK]

          if wager_legal?
            actions_without_wager << AcpcPokerTypes::PokerAction::RAISE
          else
            actions_without_wager
          end
        else
          actions_without_wager = [AcpcPokerTypes::PokerAction::CHECK]

          if wager_legal?
            actions_without_wager << AcpcPokerTypes::PokerAction::BET
          else
            actions_without_wager
          end
        end
      )
    end

    def wager_legal?(player = next_player_to_act)
      !facing_all_in?(player)
    end

    def facing_all_in?(player = next_player_to_act)
      chip_contributions_after_calling(player) >= @game_def.chip_stacks[position_relative_to_dealer(player)]
    end

    def chip_contributions_after_calling(player = next_player_to_act)
      player.chip_contributions.inject(:+) + amount_to_call(player)
    end

    # @return [Boolean] +true+ if the current hand is the last in the match.
    def last_hand?
      # @todo make sure +@match_state.hand_number+ is not greater than @number_of_hands
      return false unless @transition.next_state

      @transition.next_state.hand_number == @number_of_hands - 1
    end

    def big_blind
      player_blind_relation.values.max
    end
    def big_blind_payer
      player_blind_relation.key big_blind
    end
    def small_blind
      player_blind_relation.values.sort[-2]
    end
    def small_blind_payer
      player_blind_relation.key small_blind
    end

    private

    def player_contributed_to_pot_this_round?(player=next_player_to_act)
      player.chip_contributions.last > 0
    end

    # @todo Change MST#next_state to current_state
    def chips_contributed_to_pot_this_round?(round=@transition.next_state.round)
      chip_contributions.inject(0) do |all_contributions, contributions|
        all_contributions += contributions[round].to_r
      end > 0
    end

    def player_sees_wager?(player=next_player_to_act)
      return false unless player
      amount_to_call(player) > 0
    end

    def users_position_relative_to_dealer() @transition.next_state.position_relative_to_dealer end

    def start_new_hand!
      @player_acting_sequence = [[]]

      @players.each do |player|
        player.start_new_hand!(
          @game_def.blinds[position_relative_to_dealer(player)],
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

      action_with_context = AcpcPokerTypes::PokerAction.new(
        @transition.next_state.last_action.to_s,
        cost: cost_of_action(
          player_who_acted_last,
          @transition.next_state.last_action
        )
      )
      unless action_with_context.to_s == 'f'
        last_amount_called = amount_to_call(player_who_acted_last)
        @min_wager = AcpcPokerTypes::ChipStack.new(
          [
            @min_wager.to_r,
            action_with_context.cost.to_r - last_amount_called
          ].max
        )
      end

      player_who_acted_last.take_action!(
        action_with_context,
        pot_gained_chips: chips_contributed_to_pot_this_round?(@transition.next_state.round_in_which_last_action_taken),
        sees_wager: player_sees_wager?(player_who_acted_last)
      )

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

      # @todo This only works for Doyle's game where there are no side-pots.
      if 1 == non_folded_players.length
        non_folded_players.first.take_winnings! pot
      else
        players_and_their_hand_strength = {}
        non_folded_players.each do |player|
          hand_strength = AcpcPokerTypes::PileOfCards.new(board_cards.flatten + player.hole_cards).to_poker_hand_strength

          players_and_their_hand_strength[player] = hand_strength
        end

        strength_of_strongest_hand = players_and_their_hand_strength.values.max
        winning_players = players_and_their_hand_strength.find_all do |player, hand_strength|
          hand_strength == strength_of_strongest_hand
        end.map { |player_with_hand_strength| player_with_hand_strength.first }

        amount_each_player_wins = pot/winning_players.length.to_r

        winning_players.each do |player|
          player.take_winnings! amount_each_player_wins
        end
      end
    end

    def pot
      chip_contributions.flatten.inject(:+)
    end

    def set_min_wager!
      @min_wager = @game_def.min_wagers[@transition.next_state.round]
    end
  end
end