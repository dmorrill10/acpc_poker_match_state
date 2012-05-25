
# System classes
require 'set'

# Local modules
require File.expand_path('../acpc_poker_match_state_defs', __FILE__)

# Gems
require 'acpc_poker_types'

# The state of a poker match.
class MatchState
   include AcpcPokerTypesDefs
   include AcpcPokerMatchStateDefs
   
   # @todo Comment these
   attr_reader :pot
   attr_reader :players
   attr_reader :game_definition
   attr_reader :player_names
   attr_reader :number_of_hands
   attr_reader :betting_sequence
   
   # @param [GameDefinition] game_definition The definition of the game being played.
   # @param [Integer] users_seat The user's seat (zero indexed).
   # @param [Array] player_names The names of the players in this match.
   # @param [Integer] number_of_hands The number of hands in this match.
   def initialize(game_definition, users_seat, player_names, number_of_hands)
      @game_definition = game_definition
      # @todo Ensure that @player_names.length == @game_definition.number_of_players
      @player_names = player_names
      @number_of_hands = number_of_hands
      
      @players = PlayersAtTheTable.seat_players create_players, users_seat,
         @game_definition.first_positions_relative_to_dealer,
         @game_definition.blinds
         
      @transition = MatchStateTransition.new
      
      set_initial_internal_state!
   end
   
   # @param [MatchStateString] match_state_string The next match state.
   # @return [MatchState] The updated version of this +MatchState+.
   def update!(match_state_string)
      @transition.next_state! match_state_string do
         @players.update! match_state_string
      
         if @transition.initial_state?
            betting_sequence = [[]]
         else
            betting_sequence.last << 
            if @transition.new_state?
               betting_sequence << []
            end
         end
         
         evaluate_end_of_hand! if @players.hand_ended?
      #   @pot.round = @match_state_string.round
      #   # @todo When pot actually becomes an array of side pots this will become: @pot_values_at_start_of_round = @pot.map { |side_pot| side_pot.to_i }
      #   @pot_values_at_start_of_round = @pot.to_i if in_new_round? || hand_ended?
      #end
      end
      
      self
   end
   
   def number_of_players
      @game_definition.number_of_players
   end
   
   def player_acting_sequence
      @players.player_acting_sequence
   end
   
   def player_acting_sequence_string
      @players.player_acting_sequence_string
   end
   
   # @todo The logic for these should be moved into PlayerManager
   # Convienence methods for retrieving particular players
   
   def player_who_submitted_sb
      blinds_without_bb = @players.blinds.dup
      blinds_without_bb.delete @players.blinds.max
      pos_rel_dealer_of_sb = blinds_without_bb.index blinds_without_bb.max
      @players.players.find do |player|
         @players.position_relative_to_dealer(player) == pos_rel_dealer_of_sb
      end
   end
   
   def player_who_submitted_bb
      pos_rel_dealer_of_bb = @players.blinds.index @players.blinds.max
      @players.players.find do |player|
         @players.position_relative_to_dealer(player) == pos_rel_dealer_of_bb
      end
   end
   
   def next_player_to_act      
      @players.next_player_to_act
   end
   
   # @return The +Player+ who acted last or nil if none have played yet.
   def player_who_acted_last
      @players.player_who_acted_last
   end
   
   # (see GameCore#player_with_the_dealer_button)
   def player_with_the_dealer_button      
      @players.player_wih_dealer_button
   end   
   
   def user_player
      @players.user_player
   end
   
   # @return [Array<Player>] The players who are active.
   def active_players
      @players.active_players
   end
   
   #@return [Array<Player>] The players who have not folded.
   def non_folded_players
      @players.non_folded_players
   end
   
   def opponents
      @players.opponents
   end
   
   # return [Array] The list of players that have not yet folded.
   def non_folded_players
      @players.non_folded_players
   end
   
   # return [Array] The list of players who have folded.
   def folded_players
      @players.players - @players.non_folded_players
   end 
   
   # @see MatchStateString#position_relative_to_dealer
   def users_position
      @match_state_string.position_relative_to_dealer
   end
   
   def amounts_to_call
      @players.inject({}) do |hash, player|
         hash[player.name] = @pot.amount_to_call(player).to_i
         hash
      end
   end
   
   # Convenience game logic methods
   
   # @return [Boolean] +true+ if the match has ended, +false+ otherwise.
   def match_ended?      
      hand_ended? && last_hand?
   end
   
   # @return [Boolean] +true+ if it is the user's turn to act, +false+ otherwise.
   def users_turn_to_act?
      users_turn_to_act = position_relative_to_dealer_next_to_act == @match_state_string.position_relative_to_dealer
      users_turn_to_act &= !hand_ended?
   end
   
   # @return [Boolean] +true+ if the current hand is the last in the match.
   def last_hand?
      # @todo make sure +@match_state_string.hand_number+ is not greater than @number_of_hands
      @match_state_string.hand_number == @number_of_hands - 1
   end

   def is_reverse_blinds?
      2 == @game_definition.number_of_players
   end
   
   def last_round?
      @game_definition.number_of_rounds - 1 == @match_state_string.round 
   end
   
   # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
   def hand_ended?
      @players.hand_ended?
   end
   
   def less_than_two_non_folded_players?   
      @players.less_than_two_non_folded_players?
   end
   
   def reached_showdown?
      @players.less_than_two_non_folded_players?
   end
   
   # @return [Boolean] +true+ if any opponents cards are visible, +false+ otherwise.
   def opponents_cards_visible?
      @players.opponents_cards_visible?
   end
   
   def chip_stacks
      @players.chip_stacks
   end
   
   # return [Integer] The list containing each player's current chip balance.
   def chip_balances
      @players.chip_balances
   end
   
   # @return [Set] The set of legal actions for the currently acting player.
   def legal_actions
      list_of_action_symbols = if acting_player_sees_wager?
         [:call, :fold, :raise]
      elsif acting_player_contributed_to_the_pot_this_round?
         [:check, :raise]
      else
         [:check, :bet]
      end
      
      list_of_action_symbols.inject(Set.new) do |set, action_symbol|
         set << PokerAction.new(action_symbol)
      end         
   end
   
   def betting_sequence_string
      # @todo this should be the new matchstate where the 
      @match_state_string.betting_sequence_string
   end
   
   def acting_player_sees_wager?
      @pot.amount_to_call(player_whose_turn_is_next) > 0
   end
   
   def min_wager
      @game_definition.min_wagers[@match_state_string.round]
   end
   
   private
   
   # @todo Move to ChipManager
   def take_small_blind!
      small_blind_player = player_who_submitted_small_blind
      small_blind_player.current_wager_faced = @game_definition.small_blind
      small_blind_player.call_current_wager!
      small_blind_player.current_wager_faced = @game_definition.big_blind - @game_definition.small_blind
   end

   def create_players
      players = []
      @game_definition.number_of_players.times do |seat|
         name = @player_names[seat]   
         stack = ChipStack.new @game_definition.chip_stacks[seat]
         
         players << Player.join_match(name, seat, stack)
      end
      
      players
   end

   def start_new_hand!
      reset_players!
      set_initial_internal_state!
   end
   
   def set_initial_internal_state!
      @pot = create_new_pot
      @betting_sequence = [[]]
   end
   
   # @todo Move to PlayerManager
   def reset_actions_taken_in_current_round!
      @players.each do |player|
         player.actions_taken_in_current_round.clear
      end
   end
   
   # @todo Move to ChipStackManager
   def create_new_pot
      #pot = SidePot.new player_who_submitted_big_blind, @game_definition.big_blind
      #pot.contribute! player_who_submitted_small_blind, @game_definition.small_blind
      #pot
   end
   
   def acting_player_contributed_to_the_pot_this_round?
      amount_contributed_over_all_rounds =
         @pot.players_involved_and_their_amounts_contributed[player_whose_turn_is_next]
      
      amount_contributed_over_current_round =
         amount_contributed_over_all_rounds[@match_state_string.round]
      
      amount_contributed_over_all_rounds && amount_contributed_over_current_round &&
         (amount_contributed_over_current_round > 0)
   end

   # @todo Move to PlayerManager
   def assign_users_cards!
      user = user_player
      user.hole_cards = @match_state_string.users_hole_cards
   end
   
   # @todo Move to PlayerManager
   def assign_hole_cards_to_opponents!
      list_of_opponent_players.each do |opponent|
         opponent.hole_cards = @match_state_string.list_of_hole_card_hands[opponent.position_relative_to_dealer] unless opponent.has_folded
      end
   end
   
   def evaluate_end_of_hand!
      #@pot.distribute_chips! @match_state_string.board_cards
   end
   
   # @todo Move to PlayerManager
   def update_state_of_players!
      last_player_to_act = @players[player_who_acted_last_index]
      
      if @last_round != @match_state_string.round
         reset_actions_taken_in_current_round!
      else
         last_player_to_act.actions_taken_in_current_round << @match_state_string.last_action
      end

      acpc_action = @match_state_string.last_action.to_acpc_character
      if 'c' == acpc_action || 'k' == acpc_action
         @pot.take_call! last_player_to_act
      elsif 'f' == acpc_action
         last_player_to_act.has_folded = true
      elsif 'r' == acpc_action || 'b' == acpc_action
         amount_put_in_pot_after_calling = @pot.players_involved_and_their_amounts_contributed[last_player_to_act].sum + @pot.amount_to_call(last_player_to_act)
         amount_to_raise_to = if @match_state_string.last_action.modifier
            @match_state_string.last_action.modifier
         else
            @minimum_wager + amount_put_in_pot_after_calling
         end
         @pot.take_raise! last_player_to_act, amount_to_raise_to
         @minimum_wager = amount_to_raise_to - amount_put_in_pot_after_calling
      else
         raise PokerAction::IllegalPokerAction, acpc_action
      end
   end
   
   def remember_values_from_last_round!
      if @match_state_string
         @last_round = @match_state_string.round
         @position_relative_to_dealer_acted_last = position_relative_to_dealer_next_to_act
      end
   end
end


# From PlayersAtTheTable
#list_of_player_names = player_names_to_stack_map.keys
#      number_of_player_names = list_of_player_names.length
#      
#      difference_between_number_of_players_and_names =
#         match_state_string.number_of_players - number_of_player_names
#      
#      unless 0 == difference_between_number_of_players_and_names
#         raise IncorrectNumberOfPlayerNamesGiven,
#            difference_between_number_of_players_and_names
#      end
#      
#      @players = []
#      
#      player_information.each do |player_name, player_index|
#         name = list_of_player_names[player_index]
#         seat = player_index
#         my_position_relative_to_dealer = player_position_relative_to_dealer seat
#         position_relative_to_user = player_position_relative_to_self(number_of_player_names) - seat
#         stack = ChipStack.new player_names_to_stack_map[name].to_i
#      #   
#      #   @players << Player.new(name, seat, my_position_relative_to_dealer, position_relative_to_user, stack)
#      #end
#      
#      sanity_check_player_positions
