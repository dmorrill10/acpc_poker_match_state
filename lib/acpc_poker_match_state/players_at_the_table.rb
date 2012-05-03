
# Local modules
require File.expand_path('../acpc_poker_match_state_defs', __FILE__)

# Gems
require 'acpc_poker_types'

class PlayersAtTheTable
   include AcpcPokerTypesHelper
   #include AcpcPokerTypesDefs
   #include AcpcPokerMatchStateDefs
   
   exceptions :player_acted_before_sitting_at_table,
      :no_players_to_seat
   
   attr_reader :players
   
   alias_new :seat_players
   
   # @param [Array<Player>] players The players to seat at the table.
   def initialize(players)
      sanity_check_player_actions players
      
      @players = players
      @last_round = 0
   end
   
   # @return [Integer] The number of players seated at the table.
   def number_of_players() @players.length end
      
   # @param [MatchStateString] match_state_string The next match state.
   def update!(match_state_string)
      if first_state_of_the_first_round?
         start_new_hand!
         return
      end
      update_state_of_players!
      evaluate_end_of_hand! if hand_ended?
      @player_acting_sequence[-1] << player_who_acted_last.seat
      @player_acting_sequence << [] if match_state_string.in_new_round?(@last_round)
      
      remember_values_from_this_round!
   end
   
   private
   
   def remember_values_from_this_round!
      @last_round = match_state_string.round
   end
   
   def sanity_check_player_actions(players)
      players.each do |player|
         raise PlayerActedBeforeSittingAtTable unless player.actions_taken_in_current_round.empty?
      end
   end
   
   # @todo The logic for these should be moved into PlayerManager
   # Convienence methods for retrieving particular players
   
   # (see GameCore#player_who_submitted_small_blind)
   def player_who_submitted_small_blind      
      @players[player_who_submitted_small_blind_index]
   end
   
   # (see GameCore#player_who_submitted_big_blind)
   def player_who_submitted_big_blind      
      @players[player_who_submitted_big_blind_index]
   end
   
   # (see GameCore#player_whose_turn_is_next)
   def player_whose_turn_is_next      
      @players[player_whose_turn_is_next_index]
   end
   
   # @return The +Player+ who acted last or nil if none have played yet.
   def player_who_acted_last
      return nil if first_state_of_the_first_round?
      @players[player_who_acted_last_index]
   end
   
   # (see GameCore#player_with_the_dealer_button)
   def player_with_the_dealer_button      
      @players.each { |player| return player if dealer_position_relative_to_dealer == player.position_relative_to_dealer }
   end   
   
   def user_player
      @players.each do |player|
         return player if player.position_relative_to_user == player_position_relative_to_self(number_of_players)
      end
   end
   
   # @return [Array<Player>] The players who are active.
   def active_players
      @players.select { |player| player.is_active? }
   end
   
   #@return [Array<Player>] The players who have not folded.
   def non_folded_players
      @players.select { |player| !player.folded? }
   end
   
   def list_of_opponent_players
      local_list_of_players = @players.dup
      local_list_of_players.delete_at USERS_INDEX
      local_list_of_players
   end
   
   # return [Array] The list of players that have not yet folded.
   def list_of_players_who_have_not_folded
      @players.reject { |player| player.has_folded }
   end
   
   # return [Array] The list of players who have folded.
   def list_of_players_who_have_folded
      @players.select { |player| player.has_folded }
   end 
   
   # @todo These should be moved into PlayerManager
   # Methods for retrieving the indices of particular players
   
   def player_with_the_dealer_button_index
      @players.index { |player| dealer_position_relative_to_dealer == player.position_relative_to_dealer }
   end
 
   def player_who_submitted_big_blind_index
      big_blind_position = if is_reverse_blinds? then BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS[:submits_big_blind] else BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS[:submits_big_blind] end
      @players.index { |player| player.position_relative_to_dealer == big_blind_position }
   end
   
   def player_who_submitted_small_blind_index
      small_blind_position = if is_reverse_blinds? then BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS[:submits_small_blind] else BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS[:submits_small_blind] end
      @players.index { |player| player.position_relative_to_dealer == small_blind_position }
   end
   
   def player_whose_turn_is_next_index
      @players.index { |player| player.position_relative_to_dealer == position_relative_to_dealer_next_to_act }
   end
   
   def player_who_acted_last_index
      @players.index { |player| player.position_relative_to_dealer == @position_relative_to_dealer_acted_last }
   end
   
   # Player position reference information
   
   # @return [Integer] The position relative to the dealer that is next to act.
   # @todo I think this will not work outside of two player.
   def position_relative_to_dealer_next_to_act      
      (first_player_position_in_current_round - 1 + @match_state_string.number_of_actions_in_current_round) % active_players.length
   end
   
   # @todo Move to GameDefinition
   # @return [Integer] The user's position relative to the user.
   def users_position_relative_to_user
      @game_definition.number_of_players - 1
   end
   
   # @todo Move to GameDefinition
   # @return [Integer] The dealer's position relative to the dealer.
   def dealer_position_relative_to_dealer
      @game_definition.number_of_players - 1
   end
   
   # @todo Move to MatchStateString (it should know how many players are in
   #  this match, but I don't remember if it does yet.)
   # @param [Integer] seat A seat at the table.
   # @return [Integer] The position relative to the dealer of the given +seat+.
   def position_relative_to_dealer(seat)
      (@match_state_string.position_relative_to_dealer + seat) % @game_definition.number_of_players
   end
   
   # @return [Integer] The first player position relative to the dealer in the current round.
   def first_player_position_in_current_round
      @game_definition.first_player_position_in_each_round[@match_state_string.round]
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
      less_than_two_non_folded_players? || reached_showdown?
   end
   
   def less_than_two_non_folded_players?   
      non_folded_players.length < 2
   end
   
   def reached_showdown?
      opponents_cards_visible?
   end
   
   # @return [Boolean] +true+ if any opponents cards are visible, +false+ otherwise.
   def opponents_cards_visible?
      are_visible = (@match_state_string.list_of_opponents_hole_cards.length > 0 && !@match_state_string.list_of_opponents_hole_cards[0].empty?)
   end
   
   # Player chip information
   
   # (see GameCore#list_of_player_stacks)
   def list_of_player_stacks
      @players.map { |player| player.stack }
   end
   
   # return [Integer] The list containing each player's current chip balance.
   def list_of_player_chip_balances
      @players.map { |player| player.chip_balance }
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
      
   def player_acting_sequence_string
      string = ''
      (@match_state_string.round + 1).times do |i|
         string += @player_acting_sequence[i].join('')
         string += '/' unless i == @match_state_string.round
      end
      string
   end

   def start_new_hand!
      @player_acting_sequence = [[]]
      
      @players.each_index do |i|
         @players[i].is_all_in = false
         @players[i].has_folded = false
         @players[i].chip_stack = ChipStack.new @game_definition.list_of_player_stacks[i] # @todo if @is_doyles_game
         @players[i].position_relative_to_dealer = position_relative_to_dealer @players[i].seat
         @players[i].hole_cards = Hand.new
      end
      
      reset_actions_taken_in_current_round!
      assign_users_cards!
   end
   
   def reset_actions_taken_in_current_round!
      @players.each do |player|
         player.actions_taken_in_current_round.clear
      end
   end
   
   def assign_users_cards!
      user = user_player
      user.hole_cards = @match_state_string.users_hole_cards
   end
   
   def assign_hole_cards_to_opponents!
      list_of_opponent_players.each do |opponent|
         opponent.hole_cards = @match_state_string.list_of_hole_card_hands[opponent.position_relative_to_dealer] unless opponent.has_folded
      end
   end
   
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
end
