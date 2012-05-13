
require File.expand_path('../support/spec_helper', __FILE__)

# Local classes
require File.expand_path('../../lib/acpc_poker_match_state/players_at_the_table', __FILE__)


# @todo Move this to its own gem ##########33

class Symbol
   def to_setter_signature
      "#{self}=".to_sym
   end
end

require 'acpc_poker_types/mixins/utils'

class TestExample
   
   exceptions :no_properties_for_given, :no_properties_for_then
   
   attr_reader :description
   
   attr_reader :given
   
   attr_reader :then
   
   def initialize(example_description, example_data_catagories)
      @description = example_description
      
      @given = {}
      @then = {}
      
      given_properties = example_data_catagories[:given]
      
      raise NoPropertiesForGiven unless given_properties
      
      then_properties = example_data_catagories[:then]
      
      raise NoPropertiesForThen unless then_properties
      
      given_properties.each do |property|
         define_getter_and_setter @given, property
      end
      
      then_properties.each do |property|
         define_getter_and_setter @then, property
      end
   end
   
   def to_s
      given_as_string = partition_to_string @given
      then_as_string = partition_to_string @then
      
      "#{@description}: given: #{given_as_string}, then: #{then_as_string}"
   end
   
   private
   
   def partition_to_string(partition)
      partition.map do |key_value_pair|
         key_value_pair.join(' is ')
      end.join(', and')
   end
   
   def define_getter_and_setter(instance_on_which_to_define, property)
      define_getter instance_on_which_to_define, property
      define_setter instance_on_which_to_define, property
   end
   
   def define_getter(instance_on_which_to_define, property)
      signature = property.to_sym
      instance_on_which_to_define.singleton_class.send(:define_method, signature) do
         instance_on_which_to_define[property.to_sym]
      end
   end
   
   def define_setter(instance_on_which_to_define, property)
      signature = property.to_sym.to_setter_signature
      instance_on_which_to_define.singleton_class.send(:define_method, signature) do |to_set|
         store(property.to_sym, to_set)
      end
   end
end

###############





describe PlayersAtTheTable do
   
   INITIAL_STACK_SIZE = 2000
   SMALL_BET = 100
   
   describe '::seat_players' do
      describe 'raises an exception if it is given' do
         describe 'a player list' do
            it 'that is empty' do
               expect do
                  PlayersAtTheTable.seat_players(
                     [], 0, first_positions_relative_to_dealer(1), blinds(0))
               end.to raise_exception(PlayersAtTheTable::NoPlayersToSeat)
            end
            describe 'where at least one player' do
               it 'has already acted' do
                  various_numbers_of_players do |number_of_players|
                     player_list = init_vanilla_player_list(number_of_players)
                     
                     player_list[0].stubs(:actions_taken_in_current_hand).returns([[mock('Action')]])
                     expect do
                        PlayersAtTheTable.seat_players(
                           player_list, 0, first_positions_relative_to_dealer(1),
                           blinds(player_list.length))
                     end.to raise_exception(PlayersAtTheTable::PlayerActedBeforeSittingAtTable)
                  end
               end
               it 'has the same seat as another' do
                  various_numbers_of_players do |number_of_players|
                     player_list = init_vanilla_player_list(number_of_players)
                     
                     next if player_list.length < 2
                     
                     player_list.last.stubs(:seat).returns(0)
                     
                     expect do
                     PlayersAtTheTable.seat_players(
                        player_list, 0, first_positions_relative_to_dealer(1),
                        blinds(player_list.length))
                     end.to raise_exception(PlayersAtTheTable::MultiplePlayersHaveTheSameSeat)
                  end
               end
            end
         end
         describe 'a user seat' do
            it 'that is out of bounds' do
               [-1, 2].each do |out_of_bounds_seat|
                  player_list = init_two_player_list
                  expect do
                     PlayersAtTheTable.seat_players(
                        player_list, out_of_bounds_seat,
                        first_positions_relative_to_dealer(1),
                        blinds(player_list.length))
                  end.to raise_exception(PlayersAtTheTable::UsersSeatOutOfBounds)
               end
               player_list = init_two_player_list
               # Increment each player's seat in order to make sure no player is in seat zero
               player_list.map do |player|
                  old_seat = player.seat
                  player.stubs(:seat).returns(old_seat + 1)
               end
                  
               expect do
                  PlayersAtTheTable.seat_players(
                     player_list, 0, first_positions_relative_to_dealer(1),
                     blinds(player_list.length))
               end.to raise_exception(PlayersAtTheTable::UsersSeatOutOfBounds)
            end
         end
         describe 'a list of first positions relative to the dealer' do
            it 'that is empty' do
               various_numbers_of_players do |number_of_players|
                  player_list = init_vanilla_player_list(number_of_players)
                  
                  expect do
                     PlayersAtTheTable.seat_players(player_list, 0, [],
                                                    blinds(player_list.length))
                  end.to raise_exception(PlayersAtTheTable::InsufficientFirstPositionsProvided)
               end
            end
            it 'where a position is out of bounds' do
               various_numbers_of_players do |number_of_players|
                  player_list = init_vanilla_player_list(number_of_players)
                  
                  expect do
                     PlayersAtTheTable.seat_players(player_list, 0,
                                                    [player_list.length],
                                                    blinds(player_list.length))
                  end.to raise_exception(PlayersAtTheTable::FirstPositionOutOfBounds)
               end
            end
         end
         describe 'blinds' do
            it 'where a blind position is out of bounds' do
               various_numbers_of_players do |number_of_players|
                  player_list = init_vanilla_player_list(number_of_players)
                  
                  expect do
                     PlayersAtTheTable.seat_players(
                        player_list, 0, first_positions_relative_to_dealer(1),
                           {player_list.length => 100})
                  end.to raise_exception(PlayersAtTheTable::BlindPositionOutOfBounds)
               end
            end
         end
      end
      it 'works properly' do
         various_numbers_of_players do |number_of_players|
            player_list = init_vanilla_player_list(number_of_players)
            
            player_list.length.times do |users_seat|
               check_various_valid_creation_configurations(player_list,
                                                           users_seat) { |example| }
            end
         end
      end
   end
   describe '#update!' do
      describe 'keeps track of player positions and stacks' do
         it 'after the initial state, before any actions' do
            various_numbers_of_players do |number_of_players|
               number_of_players.times do |users_seat|
                  player_list = init_vanilla_player_list(number_of_players)
                  
                  check_various_valid_initial_update_configurations(player_list,
                                                                    users_seat) { |example| }
               end
            end
         end
         describe 'in two player' do
            describe 'limit' do
               describe 'when both players always call' do
                  it 'after one round' do
                     check_always_call_first_round_works_in_two_player_limit { |example| }
                  end
                  it 'after an entire hand with four rounds' do
                     pending
                  end
               end
            end
         end
      end
   end

   def check_always_call_first_round_works_in_two_player_limit
      player_list = init_two_player_list
      
      check_various_valid_initial_update_configurations(player_list) do |prev_example|
         action = init_vanilla_action
         action.stubs(:to_acpc_character).returns(PokerAction::LEGAL_ACTIONS[:call])
         
         match_state = prev_example.given.match_state_string
         match_state.stubs(:last_action).returns(action)
         match_state.stubs(:first_state_of_first_round?).returns(false)
         match_state.stubs(:in_new_round?).with(match_state.round).returns(false)
         
         players = prev_example.then.players
         players.each_index do |i|
            player = players[i]
            
            player.stubs(:active?).returns(true)
            player.stubs(:folded?).returns(false)
            player.stubs(:hole_cards).returns(@hands[i])
         end
         
         player_who_acted_last = prev_example.then.next_player_to_act
         index_of_player_who_acted_last = players.index(player_who_acted_last)
         
         player_acting_sequence = [[index_of_player_who_acted_last]]
         
         actions_taken_in_current_hand = [].fill [[]], 0..(players.length-1)
         actions_taken_in_current_hand[index_of_player_who_acted_last][match_state.round] << action
         
         action_appended = states('action_appended').starts_as('no')
         player_who_acted_last.expects(:take_action!).with(action).then(action_appended.is('yes'))
         player_who_acted_last.stubs(:actions_taken_in_current_hand).returns(
            actions_taken_in_current_hand[index_of_player_who_acted_last]
         ).when(action_appended.is('yes'))
         
         next_player_to_act = players.find { |player| !player.equals?(player_who_acted_last) }
         
         example = update_example match_state, players, player_acting_sequence,
            next_player_to_act, player_who_acted_last
         
         @patient.update! example.given.match_state_string
         
         # Actions: c
         check_patient example.then
         
         # Actions: cc
         pending 'time'
         
         yield example         
      end
   end
   def check_various_valid_initial_update_configurations(player_list, users_seat=0)
      check_various_valid_creation_configurations(player_list,
                                                  users_seat) do |prev_example|
         match_state = initial_vanilla_match_state prev_example.then.players,
            prev_example.given.users_seat
         
         opponent_hand = init_vanilla_hand
         @hands = [].fill opponent_hand, 0..(prev_example.then.number_of_players - 1)
         Hand.stubs(:new).returns(opponent_hand)
         
         @hands[@initial_example.given.users_seat] = match_state.users_hole_cards
         
         prev_example.then.players.each_index do |i|
            player = prev_example.then.players[i]
            
            player.stubs(:active?).returns(true)
            
            player.expects(:start_new_hand!).with(@initial_example.given.blinds[i],
                                                  INITIAL_STACK_SIZE,
                                                  @hands[i])
         end
         
         example = update_example match_state, prev_example.then.players, [[]],
            prev_example.then.players[prev_example.given.first_positions_relative_to_dealer[0]]
         
         @patient.update! example.given.match_state_string
         
         check_patient example.then
         
         yield example
      end
   end
   def check_various_valid_creation_configurations(player_list, users_seat=0)
      number_of_players = player_list.length
      
      example_first_positions = first_positions_relative_to_dealer(number_of_players)
         
      @initial_example = creation_example player_list, users_seat,
         example_first_positions
         
      @patient = PlayersAtTheTable.seat_players(
         @initial_example.given.players, @initial_example.given.users_seat,
         @initial_example.given.first_positions_relative_to_dealer,
         @initial_example.given.blinds)
         
      check_patient @initial_example.then
         
      yield @initial_example
   end
   def update_example(match_state, expected_players,
                      expected_player_acting_sequence,
                      next_player_to_act, player_who_acted_last=nil)
      example = init_players_at_the_table_example(
         "check update! when given matchstate #{match_state}",
         [:match_state_string])
         
      example.given.match_state_string = match_state
      
      example.then.players = expected_players
      example.then.round = match_state.round
      example.then.player_acting_sequence = expected_player_acting_sequence
      example.then.number_of_players = expected_players.length
      example.then.player_who_acted_last = player_who_acted_last
      example.then.next_player_to_act = next_player_to_act
      
      example
   end
   def creation_example(player_list, users_seat, example_first_positions)
      example = init_players_at_the_table_example(
         "check creation for #{player_list.length}, where the user's " +
         "seat is #{users_seat}, and the first positions relative to " +
         "the dealer in each round are #{example_first_positions}",
         [:players, :users_seat, :first_positions_relative_to_dealer, :blinds])
         
      example.given.players = player_list
      example.given.users_seat = users_seat
      example.given.first_positions_relative_to_dealer = example_first_positions
      example.given.blinds = reverse_blinds player_list.length
      
      example.then.players = player_list
      example.then.round = nil
      example.then.player_acting_sequence = nil
      example.then.number_of_players = player_list.length
      example.then.player_who_acted_last = nil
      example.then.next_player_to_act = nil
      
      example
   end
   def init_players_at_the_table_example(description, given_parameters)
      TestExample.new(
         description, {given: given_parameters,
                       then: [:players, :round, :player_acting_sequence,
                              :number_of_players, :player_who_acted_last,
                              :next_player_to_act]})
   end
   def initial_vanilla_match_state(player_list, users_seat=0)
      match_state = mock 'MatchStateString'
      
      match_state.stubs(:first_state_of_first_round?).returns(true)
      match_state.stubs(:position_relative_to_dealer).returns(users_seat)
      match_state.stubs(:round).returns(0)
      
      player_list.each do |player|
         player.stubs(:equals?).returns(false)
         player.stubs(:equals?).with(player).returns(true)
      end
      
      users_hand = init_vanilla_hand
      users_hand.stubs(:empty?).returns(false)
      
      match_state.stubs(:users_hole_cards).returns(users_hand)
      
      match_state
   end
   def init_vanilla_hand
      hand = mock 'Hand'
      hand.stubs(:empty?).returns(true)
      
      hand
   end
   def init_vanilla_action
      action = mock 'PokerAction'
      
      action
   end
   def various_numbers_of_players
      10.times do |i|
         yield i+2
      end
   end
   def init_vanilla_player_list(number_of_players)
      player_list = []
      number_of_players.times do |seat|
         player_list << init_vanilla_player(seat)
      end
      
      player_list
   end
   def init_two_player_list
      init_vanilla_player_list(2)
   end
   def init_vanilla_player(seat)
      player = mock('Player')
      player.stubs(:actions_taken_in_current_hand).returns([[]])
      player.stubs(:seat).returns(seat)      
      player.stubs(:chip_stack).returns(INITIAL_STACK_SIZE)
      
      player
   end
   def blinds(number_of_players)
      hash = zero_blinds number_of_players
      hash[0] = SMALL_BET/2
      hash[1] = SMALL_BET
      
      hash
   end
   def reverse_blinds(number_of_players)
      hash = zero_blinds number_of_players
      hash[0] = SMALL_BET
      hash[1] = SMALL_BET/2
      
      hash
   end
   def zero_blinds(number_of_players)
      hash = {}
      number_of_players.times do |i|
         hash[i] = 0
      end
      
      hash
   end
   def first_positions_relative_to_dealer(number_of_rounds)
      [].fill 0, 0..(number_of_rounds - 1)
   end
   def check_patient(then_values)
      @patient.players.should == then_values.players
      @patient.round.should == then_values.round
      @patient.player_acting_sequence.should == then_values.player_acting_sequence
      @patient.number_of_players.should == then_values.number_of_players
      @patient.player_who_acted_last.should == then_values.player_who_acted_last
      @patient.next_player_to_act.should == then_values.next_player_to_act
   end
   
   
   
   def always_call_state_sequence(number_of_rounds, player_list)
      
      
      # @todo Refactor this block ############
      
      
      
      acting_player_index = (@fprtd[initial_match_state.round] + 0) % player_list.length
      player_acting_sequence = [[acting_player_index]]
      
      
      
      
      initial_match_state = initial_round_vanilla_match_state_with_action initial_match_state
      yield initial_match_state, player_acting_sequence
      
      # @todo Refactor this block ############
      
      
      
      
      sequence_of_vanilla_match_states_over_rounds(initial_match_state,
                                                   number_of_rounds,
                                                   player_list) do |match_state|
         player_acting_sequence << []
         
         unless 0 == match_state.round
            each_player_actions_taken_in_current_hand.each do |action_list|
               action_list << []
            end
            player_list.each { |player| player.expects(:start_next_round!) }
         end
         
         states_per_round = player_list.length
         states_per_round.times do |state_number|
            
            match_state.stubs(:last_action).returns(action)
            
            acting_player_index = (@fprtd[match_state.round] + state_number) % player_list.length
            
            player_acting_sequence.last << acting_player_index
            
            puts "acting_player_index: #{acting_player_index}"
            
            action_appended = states('action_appended').starts_as('no')
            
            actions_before = []
            each_player_actions_taken_in_current_hand[acting_player_index].each do |elem|
               actions_before << elem.dup
            end            
            player_list[acting_player_index].stubs(:actions_taken_in_current_hand).returns(actions_before).when(action_appended.is('no'))
            
            each_player_actions_taken_in_current_hand[acting_player_index].last << action
            
            puts "each_player_actions_taken_in_current_hand before: #{actions_before}"
            puts "each_player_actions_taken_in_current_hand after: #{each_player_actions_taken_in_current_hand}"
            
            player_list[acting_player_index].expects(:take_action!).with(action).then(action_appended.is('yes'))
            player_list[acting_player_index].stubs(:actions_taken_in_current_hand).returns(each_player_actions_taken_in_current_hand[acting_player_index]).when(action_appended.is('yes'))
            
            player_list.each do |player|
               player.stubs(:active?).returns(true)
               player.stubs(:folded?).returns(false)
            end
            
            yield match_state, player_acting_sequence
         end
      end
   end
   def opponents_from_players(players)
      opponents = []
      players.each_index do |i|
         opponents << player_list[i] unless USERS_SEAT == i
      end
      opponents
   end
   def sequence_of_vanilla_match_states_over_rounds(initial_match_state,
                                                    number_of_rounds,
                                                    player_list)      
      (number_of_rounds-1).times do |round|
         initial_match_state.stubs(:round).returns(round+1)
         initial_match_state.stubs(:in_new_round?).with(round+1).returns(false)
         initial_match_state.stubs(:in_new_round?).with(round).returns(true)
         
         yield initial_match_state
      end
   end
   def initial_round_vanilla_match_state_with_action(previous_match_state)
      previous_match_state.stubs(:first_state_of_first_round?).returns(false)
      previous_match_state.stubs(:round).returns(0)
      previous_match_state.stubs(:in_new_round?).with(0).returns(false)
      
      previous_match_state
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