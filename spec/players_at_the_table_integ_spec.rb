
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
      it 'keeps track of state for a sequence of match states and actions' do
         # @todo Move into data retrieval method
         DealerData::DATA.each do |num_players, data_by_num_players|
            @number_of_players = num_players
            ((0..(num_players-1)).map{ |i| (i+1).to_s }).each do |seat|
               data_by_num_players.each do |type, data_by_type|
                  turns = data_by_type[:actions]
                  
                  # Setup
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
                  
                  @players = []
                  
                  num_players.times do |i|
                     name = "p#{i + 1}"
                     player_seat = i
                     @players << Player.join_match(name, player_seat, stack_size)
                  end
                  
                  @patient = PlayersAtTheTable.seat_players @players, users_seat,
                     first_positions_relative_to_dealer, blinds
                  
                  # Sample the dealer match string and action data
                  number_of_states = 200
                  number_of_states.times do |i|
                     turn = turns[i]
                     next_turn = turns[i + 1]
                     
                     puts "next_turn: seat of acting player: #{next_turn[:from_players]}"
                     
                     index_of_next_player_to_act = next_turn[:from_players].keys.first.to_i - 1
                     if index_of_next_player_to_act < 0
                        @next_player_to_act = nil
                     else
                        @next_player_to_act = @players[index_of_next_player_to_act]
                     end
                     
                     from_player_message = turn[:from_players]
                     
                     match_state_string = turn[:to_players][seat]
                     
                     prev_round = if @match_state then @match_state.round else nil end
                     @match_state = MatchStateString.parse match_state_string
                     
                     @hole_card_hands = order_by_seat_from_dealer_relative @match_state.list_of_hole_card_hands,
                        users_seat, @match_state.position_relative_to_dealer
                     
                     if @match_state.first_state_of_first_round?
                        @player_who_acted_last = nil
                        @player_acting_sequence = []
                     else
                        seat_taking_action = from_player_message.keys.first
                        
                        @last_action = PokerAction.new from_player_message[seat_taking_action]
                        
                        seat_of_last_player_to_act = seat_taking_action.to_i - 1
                        
                        @player_who_acted_last = @players[seat_of_last_player_to_act]
                        
                        puts "@player_who_acted_last: #{@player_who_acted_last}"
                        
                        @player_acting_sequence << [] if @player_acting_sequence.empty?
                        @player_acting_sequence.last << seat_of_last_player_to_act
                     end

                     if @match_state.round != prev_round || @match_state.first_state_of_first_round?
                        @player_acting_sequence << []
                     end

                     @patient.update! @match_state
                     
                     check_patient
                  end
               end
            end
         end
      end
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
   end
end
