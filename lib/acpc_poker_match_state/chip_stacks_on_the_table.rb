
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
   attr_reader :match_state_string
   attr_reader :player_acting_sequence
   attr_reader :betting_sequence
   attr_reader :pot_values_at_start_of_round
   attr_reader :minimum_wager
   
   # @param [GameDefinition] game_definition The definition of the game being played.
   # @param [MatchStateString] match_state_string The initial state of this match.
   # @param [Array] player_names The names of the players in this match.
   # @param [Integer] number_of_hands The number of hands in this match.
   # @todo bundle player names and number of hands into something
   def initialize(game_definition, match_state_string, player_names, number_of_hands)
      @game_definition = game_definition
      # @todo Ensure that @player_names.length == @game_definition.number_of_players
      @player_names = player_names
      @number_of_hands = number_of_hands
      @match_state_string = match_state_string
      
      @players = create_players
      assign_users_cards!
      set_initial_internal_state!
   end
   
   # @param [MatchStateString] match_state_string The next match state.
   # @return [MatchState] The updated version of this +MatchState+.
   def update!(match_state_string)
      remember_values_from_last_round!
      @match_state_string = match_state_string
      if first_state_of_first_round?
         start_new_hand!
      else
         update_state_of_players!
         evaluate_end_of_hand! if hand_ended?
         @player_acting_sequence[-1] << player_who_acted_last.seat
         @betting_sequence[-1] << @match_state_string.last_action
         if in_new_round?
            @pot.round = @match_state_string.round
            @player_acting_sequence << []
            @betting_sequence << []
            @minimum_wager = @game_definition.minimum_wager_in_each_round[@match_state_string.round]
         end
         # @todo When pot actually becomes an array of side pots this will become: @pot_values_at_start_of_round = @pot.map { |side_pot| side_pot.to_i }
         @pot_values_at_start_of_round = @pot.to_i if in_new_round? || hand_ended?
      end
      
      self
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
      return nil if first_state_of_first_round?
      @players[player_who_acted_last_index]
   end
   
   # (see GameCore#player_with_the_dealer_button)
   def player_with_the_dealer_button      
      @players.each { |player| return player if dealer_position_relative_to_dealer == player.position_relative_to_dealer }
   end   
   
   def user_player
      @players[USERS_INDEX]
   end
   
   # @return [Array<Player>] The players who are active.
   def active_players
      @players.select { |player| player.active? }
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
   
   # @return [Boolean] +true+ if the current round is a later round than the round in which the last action was taken, +false+ otherwise.
   def in_new_round?
      @match_state_string.round > @last_round
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
   
   # Convenience methods
   
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
   
   # return [Integer] The minimum raise amount in the current round.
   def raise_size_in_this_round
      @game_definition.minimum_wager_in_each_round[@match_state_string.round]
   end
   
   def player_acting_sequence_string
      string = ''
      (@match_state_string.round + 1).times do |i|
         string += @player_acting_sequence[i].join('')
         string += '/' unless i == @match_state_string.round
      end
      string
   end
   
   def betting_sequence_string
      @match_state_string.betting_sequence_string(@betting_sequence)
   end
   
   def acting_player_sees_wager?
      @pot.amount_to_call(player_whose_turn_is_next) > 0
   end
   
   private
   
   # @todo Move to ChipManager
   def take_small_blind!
      small_blind_player = player_who_submitted_small_blind
      small_blind_player.current_wager_faced = @game_definition.small_blind
      small_blind_player.call_current_wager!
      small_blind_player.current_wager_faced = @game_definition.big_blind - @game_definition.small_blind
   end
   
   # @todo Move to PlayerManager
   def create_players
      # The array of players is built so that it's centered on the user.
      # The user is at index USERS_INDEX = 0, the player to the user's immediate left is
      # at index 1, etc.
      players = []
      @game_definition.number_of_players.times do |player_index|
         name = @player_names[player_index]
         seat = player_index         
         my_position_relative_to_dealer = position_relative_to_dealer seat
         position_relative_to_user = users_position_relative_to_user - player_index
         stack = ChipStack.new @game_definition.list_of_player_stacks[player_index]
         
         players << Player.new(name, seat, my_position_relative_to_dealer, position_relative_to_user, stack)
      end
      
      players
   end

   def start_new_hand!
      reset_players!
      set_initial_internal_state!
   end
   
   def set_initial_internal_state!
      @pot = create_new_pot
      # @todo Move this to PlayerManager. The betting sequence can then be
      #  reconstructed on demand by combining the acting sequence with the
      #  action list keep track of by each player.
      @player_acting_sequence = [[]]
      @betting_sequence = [[]]
      
      # @todo Move to ChipStackManager
      # @todo When pot actually becomes an array of side pots this will become: @pot_values_at_start_of_round = [0]
      @pot_values_at_start_of_round = 0
      @minimum_wager = @game_definition.minimum_wager_in_each_round.first
   end
   
   # @todo Move to PlayerManager
   def reset_players!
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
   
   # @todo Move to PlayerManager
   def reset_actions_taken_in_current_round!
      @players.each do |player|
         player.actions_taken_in_current_round.clear
      end
   end
   
   # @todo Move to ChipStackManager
   def create_new_pot
      pot = SidePot.new player_who_submitted_big_blind, @game_definition.big_blind
      pot.contribute! player_who_submitted_small_blind, @game_definition.small_blind
      pot
   end

   # @todo Move into MatchStateString
   def first_state_of_first_round?
      0 == @match_state_string.round && 0 == @match_state_string.number_of_actions_in_current_round
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
      assign_hole_cards_to_opponents!
      @pot.distribute_chips! @match_state_string.board_cards
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
