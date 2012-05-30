
# Local modules
require File.expand_path('../acpc_poker_match_state_defs', __FILE__)
require File.expand_path('../match_state_transition', __FILE__)

# Gems
require 'acpc_poker_types'

class PlayersAtTheTable
   include AcpcPokerTypesHelper
   
   exceptions :player_acted_before_sitting_at_table,
      :no_players_to_seat, :users_seat_out_of_bounds,
      :multiple_players_have_the_same_seat, :insufficient_first_positions_provided,
      :first_position_out_of_bounds, :no_player_to_act_after_n_actions
   
   attr_reader :players
   
   # @return [Array<Array<Integer>>] The sequence of seats that acted,
   #  separated by round.
   attr_reader :player_acting_sequence
   
   attr_reader :transition
   
   attr_reader :number_of_hands
   
   alias_new :seat_players
   
   # @param [Array<Player>] players The players to seat at the table.
   # @param [Integer] users_seat The user's seat at the table.
   # @param [Array<Integer>] game_def The game definition for the match these
   #  players are joining.
   # @param [Integer] number_of_hands The number of hands in this match.
   def initialize(players, users_seat, game_def, number_of_hands)
      @players = sanity_check_players players
      
      @users_seat = if users_seat.seat_in_bounds?(number_of_players) && @players.any?{|player| player.seat == users_seat}
         users_seat
      else
         raise UsersSeatOutOfBounds, @users_seat
      end
      
      @game_def = game_def
      
      @transition = MatchStateTransition.new
      
      remember_active_players!
      
      @number_of_hands = number_of_hands
   end
   
   def blinds
      @game_def.blinds
   end
   
   # @return [Integer] The number of players seated at the table.
   def number_of_players() @players.length end
   
   # @param [MatchStateString] match_state_string The next match state.
   def update!(match_state_string)
      @transition.next_state! match_state_string do         
         remember_active_players!
         
         if @transition.initial_state?
            start_new_hand!
         else            
            update_state_of_players!
            
            @player_acting_sequence.last << player_who_acted_last.seat
            @player_acting_sequence << [] if @transition.new_round?
         end
      end
   end
   
   # @return [Player] The player who acted last.
   def player_who_acted_last(players_who_could_act=@active_players_before_update,
                             state=@transition.next_state)
      return nil unless !players_who_could_act.empty? && state && state.number_of_actions_this_hand > 0
      
      player_to_act_after_n_actions state.betting_sequence[round_in_which_last_action_taken(state)].length - 1,
         round_in_which_last_action_taken(state), players_who_could_act
   end
   
   # @return [Player] The next player to act.
   def next_player_to_act(state=@transition.next_state)
      return nil unless state && !hand_ended?
      
      player_to_act_after_n_actions state.number_of_actions_this_round, state.round
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
      opponents.any? { |player| !player.hole_cards.empty? }
   end
   
   # @return [Player] The player with the dealer button.
   def player_with_dealer_button
      @players.find { |player| position_relative_to_dealer(player) == number_of_players - 1}
   end
   
   # @return [Hash<Player, #to_i] Relation from player to the blind that player paid.
   def player_blind_relation
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
      @player_acting_sequence.each_index do |i|
         per_round = @player_acting_sequence[i]
         
         actions_taken_this_round = {}
         @players.each do |player|
            actions_taken_this_round[player.seat] = player.actions_taken_this_hand[i].dup
         end
         
         per_round.each_index do |j|
            seat = per_round[j]
            
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
      @players.map { |player| player.chip_contribution }
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
      largest_contribution = @players.map do |p|
         p.chip_contribution_over_hand
      end.max - player.chip_contribution_over_hand
   end
   
   def cost_of_action(player, action, round=round_in_which_last_action_taken)
      ChipStack.new(if action.to_sym == :call
         amount_to_call player
      elsif action.to_sym == :bet || action.to_sym == :raise
         if action.modifier
            action.modifier - player.chip_contribution_over_hand
         else
            @game_def.min_wagers[round] + amount_to_call(player)
         end
      else
         0
      end)
   end
   
   # @return [Set] The set of legal actions for the currently acting player.
   def legal_actions
      list_of_action_symbols = if player_sees_wager?
         [:call, :fold, :raise]
      elsif player_contributed_to_pot_this_round?
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
      # @todo make sure +@match_state_string.hand_number+ is not greater than @number_of_hands
      @transition.next_state.hand_number == @number_of_hands - 1
   end
   
   private
   
   def player_contributed_to_pot_this_round?(player=next_player_to_act)
      player.contribution.last > 0
   end
   
   def player_sees_wager?(player=next_player_to_act)
      amount_to_call(player) > 0 ||
         (blinds[position_relative_to_dealer(player)] > 0 &&
            player.actions_taken_this_hand[0].length < 1
         )
   end
   
   def users_position_relative_to_dealer() @transition.next_state.position_relative_to_dealer end
   
   def remember_active_players!() @active_players_before_update = active_players.dup end
   
   def round_in_which_last_action_taken(state=@transition.next_state)
      if state.round != 0 && state.number_of_actions_this_round < 1
         state.round - 1
      else
         state.round
      end
   end
   
   def sanity_check_players(players)
      raise NoPlayersToSeat if players.empty?
      players.each do |player|
         if player.actions_taken_this_hand && player.actions_taken_this_hand.any? do |actions_in_round|
               !actions_in_round.empty?
            end
            raise PlayerActedBeforeSittingAtTable
         end
      end
      
      raise MultiplePlayersHaveTheSameSeat if players.uniq!{ |player| player.seat }
      
      players
   end
   
   def sanity_check_first_positions(first_positions_relative_to_dealer)
      raise InsufficientFirstPositionsProvided, 1 if first_positions_relative_to_dealer.empty?
      
      out_of_bounds_first_position = first_positions_relative_to_dealer.find do |position|
         !position.seat_in_bounds?(number_of_players)
      end
         
      if out_of_bounds_first_position
         raise FirstPositionOutOfBounds, out_of_bounds_first_position.to_s
      end
      
      first_positions_relative_to_dealer
   end
   
   def sanity_check_blinds(blinds)
      while blinds.length > number_of_players
         blinds.pop
      end
      while blinds.length < number_of_players
         blinds << 0
      end
      
      blinds
   end
   
   # @param [Integer] n A number of actions.
   # @param [Integer] round The round in which the actions were taken.
   # @param [Array<Player>] players_who_could_act The set of players who could
   #  have acted after +n+ actions in round +round+.
   # @return [Player] The player who is next to act after +n+ actions.
   # @raise InsufficientFirstPositionsProvided
   # @raise NoActionsHaveBeenTaken
   def player_to_act_after_n_actions(n, round=@transition.next_state.round,
                                     players_who_could_act=active_players)
      return nil if players_who_could_act.empty?
      
      begin
         position_relative_to_dealer_to_act = (@game_def.first_positions_relative_to_dealer[round] + n) % number_of_players
      rescue
         raise InsufficientFirstPositionsProvided, round - (@game_def.first_positions_relative_to_dealer.length - 1)
      end
      
      player_to_act = players_who_could_act.find do |player|
         position_relative_to_dealer(player) == position_relative_to_dealer_to_act
      end
      
      raise NoPlayerToActAfterNActions, n unless player_to_act
      
      player_to_act
   end
   
   def start_new_hand!
      @player_acting_sequence = [[]]
      
      @players.each_index do |i|
         player = @players[i]

         player.start_new_hand!(
            blinds[position_relative_to_dealer(player)],
            @game_def.chip_stacks[position_relative_to_dealer(player)], # @todo if playing Doyle's game
            @transition.next_state.list_of_hole_card_hands[position_relative_to_dealer(player)]
         )
      end
   end
   
   def assign_hole_cards_to_players!
      @players.each do |player|
         player.assign_cards! @transition.next_state.list_of_hole_card_hands[position_relative_to_dealer(player)]
      end
   end
   
   def update_state_of_players!
      assign_hole_cards_to_players!
      
      action_with_context = PokerAction.new(
         @transition.next_state.last_action.to_acpc,
         cost_of_action(player_who_acted_last,
                        @transition.next_state.last_action),
         nil,
         player_sees_wager?(player_who_acted_last)
      )
      player_who_acted_last.take_action! action_with_context
      
      if @transition.new_round?
         @players.each { |player| player.start_new_round! }
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
end

class Array
   def find_out_of_bounds_seat(number_of_players)
      self.find do |position|
         !position.seat_in_bounds?(number_of_players)
      end
   end
end
