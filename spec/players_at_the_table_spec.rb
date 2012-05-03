
require File.expand_path('../support/spec_helper', __FILE__)

# Local classes
require File.expand_path('../../lib/acpc_poker_match_state/players_at_the_table', __FILE__)

describe PlayersAtTheTable do
   
   describe '::seat_players' do
      describe 'raises an exception if' do
         it 'is given an empty list of players' do
            expect{PlayersAtTheTable.seat_players([])}.to
               raise_exception(PlayersAtTheTable::NoPlayersToSeat)
         end
         it 'is given at least one player who has already acted' do
            init_vanilla_player_lists do |player_list|
               player_list[0].stubs(:actions_taken_in_current_round).returns([mock('Action')])
            end
            expect{PlayersAtTheTable.seat_players(player_list)}.to
               raise_exception(PlayersAtTheTable::PlayerActedBeforeSittingAtTable)
         end
      end
      it 'keeps track of the players it seats' do
         init_vanilla_player_lists do |player_list|
            PlayersAtTheTable.seat_players(player_list).players.should == player_list
         end
      end
   end
   
   it '#number_of_players reports correctly' do
      init_vanilla_player_lists do |player_list|
         PlayersAtTheTable.seat_players(player_list).number_of_players.should == player_list.length
      end
   end
   
   describe '#update!' do
      pending 'a good way to do these tests easily'
   end
   
   def init_vanilla_player_lists
      10.times do |i|
         player_list = []
         (i+1).times do |j|
            player = mock('Player')
            player.stubs(:actions_taken_in_current_round).returns([])
            
            player_list.push player
            
            yield player_list
         end
      end
   end
   
   
   
   
   
   
   
   
   
   
   
   
   
   # @todo Move to MatchState #######
   
   #describe '::seat_players' do
   #   it 'creates players with names and starting stack amounts as given' do
   #      various_numbers_of_players_names_and_stack_sizes do |player_names_to_stack_map|
   #         match_state_string_methods_and_return_values =
   #            {number_of_players: player_names_to_stack_map.keys.length}
   #         
   #         init_match_state_string(match_state_string_methods_and_return_values) do |match_state_string|
   #            player_names_to_stack_map.keys.length.times do |seat|
   #               # Easy case: the user is always the dealer
   #               match_state_string.stubs(:position_relative_to_dealer).with(seat).returns(seat)
   #            end
   #            patient = PlayersAtTheTable.seat_players player_names_to_stack_map,
   #               match_state_string
   #            
   #            player_names = patient.players.map { |player| player.name }
   #            player_stacks = patient.players.map { |player| player.chip_stack.to_i }
   #            
   #            player_names.should be == player_names_to_stack_map.keys
   #            player_stacks.should be == player_names_to_stack_map.values
   #         end
   #      end
   #   end
   #   it 'assigns zero as a stack amount if none is given' do
   #      pending 'Updates to MatchStateString'
   #   end
   #   describe 'raises an exception if' do
   #      it 'was not given an incorrect number of player names' do
   #         incorrect_number_of_player_configurations do |player_names_to_stack_map, match_state_string|
   #            expect{PlayersAtTheTable.seat_players(player_names_to_stack_map, match_state_string)}.to
   #               raise_exception(PlayersAtTheTable::IncorrectNumberOfPlayerNamesGiven)
   #         end
   #      end
   #   end
   #end
   #
   #def incorrect_number_of_player_configurations
   #   too_many_player_names do |player_names_to_stack_map, match_state_string|
   #      yield player_names_to_stack_map, match_state_string
   #   end
   #   too_few_player_names do |player_names_to_stack_map, match_state_string| 
   #      yield player_names_to_stack_map, match_state_string
   #   end
   #end
   #
   #def too_many_player_names
   #   various_numbers_of_players_names_and_stack_sizes do |player_names_to_stack_map|
   #      init_match_state_string({number_of_players: player_names_to_stack_map.keys.length+1}) do |match_state_string|
   #         yield player_names_to_stack_map, match_state_string
   #      end
   #   end
   #end
   #
   #def too_few_player_names
   #   various_numbers_of_players_names_and_stack_sizes do |player_names_to_stack_map|
   #      init_match_state_string({number_of_players: player_names_to_stack_map.keys.length-1}) do |match_state_string|
   #         yield player_names_to_stack_map, match_state_string
   #      end
   #   end
   #end
   #
   #def init_match_state_string(stubbed_methods_return_value_map={})
   #   match_state_string = mock('MatchStateString')
   #   stubbed_methods_return_value_map.each do |method_to_stub, return_value|
   #      match_state_string.stubs(method_to_stub).returns(return_value)
   #   end
   #   yield match_state_string
   #end
   #
   #def various_numbers_of_players_names_and_stack_sizes
   #   [{'only_player_0' => 0}, {'only_player_1' => 1},
   #      {'p1' => 100, 'p2' => 200},
   #      {'p1' => 10, 'p2' => 10, 'p3' => 100}].each do |player_names_to_stack_map|
   #      yield player_names_to_stack_map
   #   end
   #end
   
   #describe 'the list of first seats' do
         #   it 'is shorter than the round number' do
         #      lists_of_first_seats_shorter_than_round_number do |list_of_first_seats, match_state|
         #         expect{MatchStateString.parse(match_state, list_of_first_seats)}.to raise_exception(MatchStateString::UnknownFirstSeat)
         #      end
         #   end
         #   it 'contains a seat that is not occupied by a player' do
         #      first_seat_in_each_round_with_one_not_occupied do |first_seat_in_each_round, match_state|
         #         expect{MatchStateString.parse(match_state, first_seat_in_each_round)}.to raise_exception(MatchStateString::FirstSeatIsUnoccupied)
         #      end
         #   end
         #end
   #it 'reports the correct first player in each round' do
   #   reports_correct_first_player do |first_seat_in_each_round|
   #      match_state = MATCH_STATE_LABEL + ':1:1::' + arbitrary_hole_card_hand + '|'
   #      first_seat_in_each_round.length.times do |i|
   #         match_state += '/Ah'
   #         patient = test_match_state_success match_state
   #         patient.first_player_in_current_round.seat.should == first_seat_in_current_round[i]
   #      end
   #   end
   #end
   
    
   # @todo From MatchStateString
   #:unknown_first_seat, :first_seat_is_unoccupied
   #@first_seat_in_each_round = validate_first_seats list_of_first_seats
   # @param [Array<Integer>] first_player_position_in_each_round The seat of the first player in each round.
   #
   #def lists_of_first_seats_shorter_than_round_number
   #   [[], [0], [0, 1]].each do |list_of_first_seats|
   #      match_state = MATCH_STATE_LABEL + ':0:0:'
   #      (list_of_first_seats.length).times do |i|
   #         match_state += 'c/'
   #      end
   #      match_state += ":#{arbitrary_hole_card_hand}|"
   #      yield list_of_first_seats, match_state   
   #   end
   #end
   #
   #def first_seat_in_each_round_with_one_not_occupied
   #   [[-3], [2], [0, 1, 2], [0, 2, 1], [2, 1, 0]].each do |first_seat_in_each_round|
   #      match_state = MATCH_STATE_LABEL + ':0:0::'
   #      [first_seat_in_each_round.min.abs-2, first_seat_in_each_round.max-1].max.times do |i|
   #         match_state += arbitrary_hole_card_hand.to_s + '|'
   #      end
   #      yield first_seat_in_each_round, match_state
   #   end
   #end
   #
   #def reports_correct_first_player
   #   [[0], [0, 0], [0, 1], [0, 1, 0, 1]].each do |first_seat_in_current_round|
   #      yield first_seat_in_current_round
   #   end
   #end
end