
require File.expand_path('../support/spec_helper', __FILE__)

# Gems
require 'acpc_poker_types/types/player'

# Local modules
require File.expand_path('../support/dealer_data', __FILE__)

require File.expand_path('../../lib/acpc_poker_match_state/players_at_the_table', __FILE__)

describe PlayersAtTheTable do
   include DealerData
   
   # @todo integrate this into the data where its collected
   GAME_DEFS = {
      limit: {
         stack_size: 400, small_bets: [2, 2, 4, 4],
         first_positions_relative_to_dealer: [1, 0, 0, 0]
      },
      nolimit: {
         stack_size: 20000, small_bets: [100, 100, 100, 100],
         first_positions_relative_to_dealer: [1, 0, 0, 0]
      }
   }
   
   describe '#update!' do
      it "keeps track of state for a sequence of match states and actions in Doyle's game" do
         # @todo Move into data retrieval method
         DealerData::DATA.each do |num_players, data_by_num_players|
            @number_of_players = num_players
            ((0..(num_players-1)).map{ |i| (i+1).to_s }).each do |seat|
               data_by_num_players.each do |type, data_by_type|
                  turns = data_by_type[:actions]
                  
                  # Data from game def
                  stack_size = GAME_DEFS[type][:stack_size]
                  small_bets = GAME_DEFS[type][:small_bets]
                  big_blind = small_bets.first
                  small_blind = big_blind/2
                  blinds = [big_blind, small_blind]
                  while blinds.length < num_players
                     blinds << 0
                  end
                  first_positions_relative_to_dealer = GAME_DEFS[type][:first_positions_relative_to_dealer]
                  users_seat = seat.to_i - 1
                  
                  # Setup players
                  @players = []
                  num_players.times do |i|
                     name = "p#{i + 1}"
                     player_seat = i
                     @players << Player.join_match(name, player_seat, stack_size)
                  end
                  @chip_balances = @players.map { |player| player.chip_balance }
                  @user_player = @players[users_seat]
                  @opponents = @players.select { |player| !player.eql?(@user_player) }
                  
                  # Initialize patient
                  @patient = PlayersAtTheTable.seat_players @players, users_seat,
                     first_positions_relative_to_dealer, blinds
                  
                  # Sample the dealer match string and action data
                  number_of_states = 200
                  number_of_states.times do |i|
                     turn = turns[i]
                     next_turn = turns[i + 1]
                     
                     index_of_next_player_to_act = next_turn[:from_players].keys.first.to_i - 1
                     @next_player_to_act = if index_of_next_player_to_act < 0
                        nil
                     else
                        @players[index_of_next_player_to_act]
                     end
                     
                     @users_turn_to_act = if @next_player_to_act
                        @next_player_to_act.seat == users_seat
                     else
                        false
                     end
                     
                     from_player_message = turn[:from_players]
                     
                     match_state_string = turn[:to_players][seat]
                     
                     prev_round = if @match_state then @match_state.round else nil end
                     @match_state = MatchStateString.parse match_state_string
                     
                     @hole_card_hands = order_by_seat_from_dealer_relative @match_state.list_of_hole_card_hands,
                        users_seat, @match_state.position_relative_to_dealer
                     
                     # Set values based on whether or not it's the initial state
                     if @match_state.first_state_of_first_round?
                        @player_who_acted_last = nil
                        @player_acting_sequence = []
                        @player_acting_sequence_string = ''
                        
                        # Adjust stacks and balances
                        @chip_stacks = []
                        @players.each_index { |j| @chip_stacks << stack_size }
                        @chip_stacks.each_index do |j|
                           @chip_stacks[j] -= blinds[positions_relative_to_dealer[j]]
                           @chip_balances[j] -= blinds[positions_relative_to_dealer[j]]
                        end
                     else
                        seat_taking_action = from_player_message.keys.first
                        
                        @last_action = PokerAction.new from_player_message[seat_taking_action]
                        #@todo Adjust stacks and balances based on last action
                        seat_of_last_player_to_act = seat_taking_action.to_i - 1
                        
                        @player_who_acted_last = @players[seat_of_last_player_to_act]
                        
                        @player_acting_sequence << [] if @player_acting_sequence.empty?
                        @player_acting_sequence.last << seat_of_last_player_to_act
                        @player_acting_sequence_string += seat_of_last_player_to_act.to_s
                     end

                     # Update values if the round or hand has changed
                     if @match_state.round != prev_round || @match_state.first_state_of_first_round?
                        @player_acting_sequence << []
                     end
                     if @match_state.round != prev_round && !@match_state.first_state_of_first_round?
                        @player_acting_sequence_string += '/'
                     end

                     # Update the patient
                     @patient.update! @match_state
                     
                     # Retrieve values to check
                     @active_players = @players.select { |player| player.active? }
                     @non_folded_players = @players.select { |player| !player.folded? }
                     @opponents_cards_visible = @opponents.any? { |player| !player.hole_cards.empty? }
                     @reached_showdown = @opponents_cards_visible
                     @less_than_two_non_folded_players = @non_folded_players.length < 2
                     @hand_ended = @less_than_two_non_folded_players || @reached_showdown
                     @player_with_dealer_button = nil
                     @players.each_index do |j|
                        if positions_relative_to_dealer[j] == @players.length - 1
                           @player_with_dealer_button = @players[j]
                        end
                     end
                     @player_blind_relation = @players.inject({}) do |hash, player|
                        hash[player] = blinds[positions_relative_to_dealer[player.seat]]
                        hash
                     end
                     
                     check_patient
                  end
               end
            end
         end
      end
   end
   
   def positions_relative_to_dealer
      positions = []
      @match_state.list_of_hole_card_hands.each_index do |pos_rel_dealer|
         @hole_card_hands.each_index do |seat|
            if @hole_card_hands[seat] == @match_state.list_of_hole_card_hands[pos_rel_dealer]
               positions[seat] = pos_rel_dealer
            end
         end
         @match_state.list_of_hole_card_hands
      end
      positions
   end
   def order_by_seat_from_dealer_relative(list_of_hole_card_hands, users_seat,
                                          users_pos_rel_to_dealer)
      new_list = [].fill Hand.new, (0..list_of_hole_card_hands.length - 1)
      list_of_hole_card_hands.each_index do |pos_rel_dealer|
         position_difference = pos_rel_dealer - users_pos_rel_to_dealer
         seat = (position_difference + users_seat) % list_of_hole_card_hands.length
         new_list[seat] = list_of_hole_card_hands[pos_rel_dealer]
      end
      
      new_list
   end
   def check_patient
      @patient.player_acting_sequence.should == @player_acting_sequence
      @patient.number_of_players.should == @number_of_players
      @patient.player_who_acted_last.should be @player_who_acted_last
      @patient.next_player_to_act.should be @next_player_to_act
      (@patient.players.map { |player| player.hole_cards }).should == @hole_card_hands
      @patient.user_player.should == @user_player
      @patient.opponents.should == @opponents
      @patient.active_players.should == @active_players
      @patient.non_folded_players.should == @non_folded_players
      @patient.opponents_cards_visible?.should == @opponents_cards_visible
      @patient.reached_showdown?.should == @reached_showdown
      @patient.less_than_two_non_folded_players?.should == @less_than_two_non_folded_players                     
      @patient.hand_ended?.should == @hand_ended
      @patient.player_with_dealer_button.should == @player_with_dealer_button
      @patient.player_blind_relation.should == @player_blind_relation
      @patient.player_acting_sequence_string.should == @player_acting_sequence_string
      @patient.users_turn_to_act?.should == @users_turn_to_act
      @patient.chip_stacks.should == @chip_stacks
      @patient.chip_balances.should == @chip_balances
      #@patient.chip_contributions.should == @chip_contributions
      #@patient.chip_balance_over_hand.should == @chip_balance_over_hand
      #@patient.match_state_string.should == @match_state
   end
end
