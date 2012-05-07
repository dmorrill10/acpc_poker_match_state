
# Local modules
require File.expand_path('../acpc_poker_match_state_defs', __FILE__)

# Gems
require 'acpc_poker_types'

class PlayersAtTheTable
   include AcpcPokerTypesHelper
   #include AcpcPokerTypesDefs
   #include AcpcPokerMatchStateDefs
   
   exceptions :player_acted_before_sitting_at_table,
      :no_players_to_seat, :users_seat_out_of_bounds,
      :multiple_players_have_the_same_seat, :insufficient_first_positions_provided,
      :first_position_out_of_bounds, :no_player_to_act_after_n_actions,
      :blind_position_out_of_bounds
   
   attr_reader :players
   
   # @return [Integer, NilClass] The current round, if a match state has been seen, otherwise +nil+.
   attr_reader :round
   
   # @return [Array<Array<Integer>>] The sequence of seats that acted, separated by round, or +nil+ if no actions have been taken.
   attr_reader :player_acting_sequence
   
   alias_new :seat_players
   
   # @param [Array<Player>] players The players to seat at the table.
   # @param [Integer] users_seat The user's seat at the table.
   # @param [Array<Integer>] first_positions_relative_to_dealer The first position
   #  relative to the dealer to act in every round.
   # @param [Hash<Integer, #to_i>] blinds The relation between the position
   #  relative to the dealer and the blind amount.
   def initialize(players, users_seat, first_positions_relative_to_dealer,
                  blinds)
      @players = sanity_check_players players
      
      @first_positions_relative_to_dealer = sanity_check_first_positions first_positions_relative_to_dealer
      
      @blinds = sanity_check_blinds blinds
      
      @users_seat = if users_seat.seat_in_bounds?(number_of_players) && @players.any?{|player| player.seat == users_seat}
         users_seat
      else
         raise UsersSeatOutOfBounds, @users_seat
      end
      
      @initial_stacks = @players.map { |player| player.chip_stack }
   end
   
   # @return [Integer] The number of players seated at the table.
   def number_of_players() @players.length end
   
   # @param [MatchStateString] match_state_string The next match state.
   def update!(match_state_string)
      @round = match_state_string.round
      @users_position_relative_to_dealer = match_state_string.position_relative_to_dealer
      
      if match_state_string.first_state_of_first_round?
         start_new_hand! match_state_string
         return remember_values_from_this_state! match_state_string
      end
         
      update_state_of_players! match_state_string
      
      @player_acting_sequence.last << player_who_acted_last.seat
      @player_acting_sequence << [] if match_state_string.in_new_round?(@last_round)
      
      remember_values_from_this_state! match_state_string
   end
   
   # @return [Player] The player who acted last.
   def player_who_acted_last
      return nil unless round && number_of_actions_in_current_round > 0
      
      player_to_act_after_n_actions number_of_actions_in_current_round - 1
   end
   
   # @return [Player] The player who is next to act.
   def next_player_to_act
      return nil unless round
      
      p1 = player_to_act_after_n_actions number_of_actions_in_current_round
      
      
      #puts "next_player_to_act: #{active_players.index { |player| player.equals?(p1)}}"
      
      p1
   end
   
   private
   
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
         @users_position_relative_to_dealer, number_of_players)
      
      player.seat.position_relative_to seat_of_dealer, number_of_players
   end
   
   def remember_values_from_this_state!(match_state_string)
      @last_round = match_state_string.round
   end
   
   def sanity_check_players(players)
      raise NoPlayersToSeat if players.empty?
      players.each do |player|
         if player.actions_taken_in_current_hand.any? do |actions_in_round|
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
      out_of_bounds_blind_position = blinds.keys.find do |position|
         !position.seat_in_bounds?(number_of_players)
      end
      
      if out_of_bounds_blind_position
         raise BlindPositionOutOfBounds, out_of_bounds_blind_position.to_s
      end
      
      blinds
   end
   
   # @param [Integer] n A number of actions.
   # @return [Player] The player who is next to act after +n+ actions.
   # @raise InsufficientFirstPositionsProvided
   # @raise NoActionsHaveBeenTaken
   def player_to_act_after_n_actions(n)
      
      #puts "@first_positions_relative_to_dealer: #{@first_positions_relative_to_dealer}, n: #{n}"
      
      begin
         position_relative_to_dealer_to_act = (@first_positions_relative_to_dealer[@round] + n) % number_of_players
      rescue
         raise InsufficientFirstPositionsProvided, @round - (@first_positions_relative_to_dealer.length - 1)
      end
      
      player_to_act = active_players.find { |player| position_relative_to_dealer(player) >= position_relative_to_dealer_to_act }
      
      raise NoPlayerToActAfterNActions, n unless player_to_act
      
      player_to_act
   end
   
   def number_of_actions_in_current_round
      @players.inject(0) do |sum, player|
         
         #puts "player.seat: #{player.seat}, actions_taken_in_current_hand: #{player.actions_taken_in_current_hand}"
         
         sum += player.actions_taken_in_current_hand[@round].length
      end
   end
   
   def start_new_hand!(match_state_string)
      @player_acting_sequence = [[]]
      
      @players.each_index do |i|
         player = @players[i]
         
         player.start_new_hand! @initial_stacks[i], # @todo if @is_doyles_game
            lambda{if user_player.equals?(player)
                     match_state_string.users_hole_cards
                  else
                     Hand.new
                  end}.call
      end
   end
   
   def assign_hole_cards_to_opponents!(match_state_string)
      opponents.each do |opponent|
         unless opponent.folded?
            opponent.hole_cards = match_state_string.list_of_hole_card_hands[position_relative_to_dealer(opponent)]
         end
      end
   end
   
   def update_state_of_players!(match_state_string)
      if @last_round != match_state_string.round
         @players.each { |player| player.start_next_round! }
      end
      
      next_player_to_act.take_action! match_state_string.last_action
      
      #puts "taken action"
      
      assign_hole_cards_to_opponents!(match_state_string) if hand_ended?
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
   
   
   
   
   
   
   # Convienence methods for retrieving particular players
   
   # (see GameCore#player_who_submitted_small_blind)
   def player_who_submitted_small_blind      
      @players[player_who_submitted_small_blind_index]
   end
   
   # (see GameCore#player_who_submitted_big_blind)
   def player_who_submitted_big_blind      
      @players[player_who_submitted_big_blind_index]
   end
   
   # (see GameCore#player_with_the_dealer_button)
   def player_with_the_dealer_button      
      @players.each { |player| return player if dealer_position_relative_to_dealer == player.position_relative_to_dealer }
   end
   
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
   
   # Player position reference information
   
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
end

class Array
   def find_out_of_bounds_seat(number_of_players)
      self.find do |position|
         !position.seat_in_bounds?(number_of_players)
      end
   end
end
