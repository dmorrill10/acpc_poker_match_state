
require File.expand_path('../support/spec_helper', __FILE__)

require 'acpc_poker_types/types/game_definition'

require File.expand_path('../../lib/acpc_poker_match_state/players_at_the_table', __FILE__)

describe PlayersAtTheTable do
   
   INITIAL_STACK_SIZE = 2000
   SMALL_BET = 100
   
   describe '::seat_players' do
      describe 'raises an exception if it is given' do
         describe 'a player list' do
            it 'that is empty' do
               expect do
                  PlayersAtTheTable.seat_players(
                     [], 0, mock('GameDefinition'), 1
                  )
               end.to raise_exception(PlayersAtTheTable::NoPlayersToSeat)
            end
            describe 'where at least one player' do
               it 'has already acted' do
                  various_numbers_of_players do |number_of_players|
                     player_list = init_vanilla_player_list(number_of_players)
                     
                     player_list[0].stubs(:actions_taken_this_hand).returns([[mock('Action')]])
                     expect do
                        PlayersAtTheTable.seat_players(
                           player_list, 0, mock('GameDefinition'), 1
                        )
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
                           player_list, 0, mock('GameDefinition'), 1
                        )
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
                        mock('GameDefinition'), 1
                     )
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
                     player_list, 0, mock('GameDefinition'), 1
                  )
               end.to raise_exception(PlayersAtTheTable::UsersSeatOutOfBounds)
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
            pending 'This unit test is too complex to be useful or maintain for now'
            
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
               it 'after a non-terminal sequence of four actions' do
                  
                  pending 'This unit test is too complex to be useful or maintain for now'
                  
                  check_non_terminal_four_action_sequence { |example| }
               end
               describe 'after a terminal sequence of five actions the sequence' do
                  it 'where the second player calls' do
                     
                     pending 'This unit test is too complex to be useful or maintain for now'
                     
                     check_non_terminal_four_action_sequence do |prev_example|
                     
                        match_state = prev_example.given.match_state_string
                        players = prev_example.then.players
                        player_acting_sequence = prev_example.then.player_acting_sequence
                        
                        player_who_acted_last = prev_example.then.next_player_to_act
                        index_of_player_who_acted_last = players.index(player_who_acted_last)
                        
                        local_index_of_next_player_to_act = index_of_next_player_to_act(
                           @initial_example.given.first_positions_relative_to_dealer[match_state.round],
                           2, players.length
                        )
                        next_player_to_act = players[local_index_of_next_player_to_act]
                        
                        player_acting_sequence.last << index_of_player_who_acted_last
                        
                        setup_actions_taken_this_hand! players, index_of_player_who_acted_last,
                           match_state.round, match_state.last_action
                        
                        match_state.stubs(:list_of_hole_card_hands).returns(@hands)
                        
                        # Cause a showdown
                        
                        users_seat = match_state.position_relative_to_dealer
                        @hands.each_index do |i|
                           @hands[i].stubs(:empty?).returns(false)
                           
                           players[i].expects(:assign_cards!).with(@hands[i]) unless i == users_seat
                        end
                        
                        prev_example = create_and_check_update_example match_state,
                           players, player_acting_sequence, next_player_to_act,
                           player_who_acted_last
                     end
                  end
               end
            end
         end
      end
   end

   def check_non_terminal_four_action_sequence
      player_list = init_two_player_list
      
      check_various_valid_initial_update_configurations(player_list) do |prev_example|
         
         init_actions_taken_in_current_round player_list.length
         
         prev_example = check_initial_call! prev_example
         
         ###### Next turn, and next round
         action = prev_example.given.match_state_string.last_action
         player_acting_sequence = prev_example.then.player_acting_sequence
         
         # Update the round
         match_state = prev_example.given.match_state_string
         last_round = match_state.round
         match_state.stubs(:round).returns(1)
         match_state.stubs(:in_new_round?).with(last_round).returns(true)
         
         # Setup player who acted and will act next turn
         players = prev_example.then.players
         
         players.each do |player|
            player.expects(:start_next_round!)
         end
         
         player_who_acted_last = prev_example.then.next_player_to_act
         index_of_player_who_acted_last = players.index(player_who_acted_last)
         
         local_index_of_next_player_to_act = @initial_example.given.first_positions_relative_to_dealer[match_state.round]
         next_player_to_act = players[local_index_of_next_player_to_act]
         
         player_acting_sequence.last << index_of_player_who_acted_last
         player_acting_sequence << []
         
         # Since this is a new round
         @actions_taken_this_hand.each_index do |i|
            @actions_taken_this_hand[i] << []
         end
         
         setup_actions_taken_this_hand! players, index_of_player_who_acted_last,
            last_round, action
         
         prev_example = create_and_check_update_example match_state, players, player_acting_sequence,
            next_player_to_act, player_who_acted_last
         
         ####### Next turn
         
         match_state = prev_example.given.match_state_string
         match_state.stubs(:last_action).returns(action)
         match_state.stubs(:round).returns(1)
         match_state.stubs(:in_new_round?).with(match_state.round).returns(false)
         
         # Setup player who acted and will act next turn
         players = prev_example.then.players
         
         player_who_acted_last = prev_example.then.next_player_to_act
         index_of_player_who_acted_last = players.index(player_who_acted_last)
         
         local_index_of_next_player_to_act = index_of_next_player_to_act(
            @initial_example.given.first_positions_relative_to_dealer[match_state.round],
            1, players.length
         )
         next_player_to_act = players[local_index_of_next_player_to_act]
         
         player_acting_sequence.last << index_of_player_who_acted_last         
         
         setup_actions_taken_this_hand! players, index_of_player_who_acted_last,
            match_state.round, action
         
         # Check result. Actions taken so far should be: cc/r
         prev_example = create_and_check_update_example match_state, players, player_acting_sequence,
            next_player_to_act, player_who_acted_last
         
         yield prev_example         
      end
   end
   def check_initial_call!(prev_example)         
      action = init_vanilla_action
      
      # Setup match state
      match_state = prev_example.given.match_state_string
      match_state.stubs(:last_action).returns(action)
      match_state.stubs(:in_new_round?).with(match_state.round).returns(false)
      match_state.stubs(:number_of_actions_this_round).returns(1)
      match_state.stubs(:number_of_actions_this_hand).returns(1)
      
      # Ensure players are active and have cards
      players = prev_example.then.players
      players.each_index do |i|
         player = players[i]
         
         player.stubs(:active?).returns(true)
         player.stubs(:folded?).returns(false)
         player.stubs(:hole_cards).returns(@hands[i])
      end
      
      # Setup player who acted and will act next turn
      player_who_acted_last = prev_example.then.next_player_to_act
      index_of_player_who_acted_last = players.index(player_who_acted_last)
      
      player_acting_sequence = [[index_of_player_who_acted_last]]
      
      setup_actions_taken_this_hand! players, index_of_player_who_acted_last,
         match_state.round, action
      
      next_player_to_act = players[index_of_next_player_to_act(
         @initial_example.given.first_positions_relative_to_dealer[0], 1,
         players.length
      )]
      
      # Check result. Actions taken so far should be: c
      create_and_check_update_example match_state, players,
         player_acting_sequence, next_player_to_act, player_who_acted_last
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
      
      game_def = mock 'GameDefinition'
      game_def.stubs(:first_positions_relative_to_dealer).returns(@initial_example.given.first_positions_relative_to_dealer)
      game_def.stubs(:blinds).returns(@initial_example.given.blinds)
      
      @patient = PlayersAtTheTable.seat_players(
         @initial_example.given.players, @initial_example.given.users_seat,
         game_def, 1
      )
         
      check_patient @initial_example.then
         
      yield @initial_example
   end
   def index_of_next_player_to_act(first_position_relative_to_dealer_in_current_round,
                                   number_of_actions_in_current_round, number_of_players)
      (first_position_relative_to_dealer_in_current_round + number_of_actions_in_current_round) % number_of_players
   end
   def create_and_check_update_example(match_state, players, player_acting_sequence, next_player_to_act,
                                       player_who_acted_last)
      example = update_example match_state, players, player_acting_sequence,
         next_player_to_act, player_who_acted_last
         
      # Initiate test
      @patient.update! example.given.match_state_string
      
      check_patient example.then
      
      example
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
      
      match_state.stubs(:number_of_actions_this_round).returns(0)
      match_state.stubs(:number_of_actions_this_hand).returns(0)
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
      action.stubs(:to_acpc_character)
      
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
      player.stubs(:actions_taken_this_hand).returns([[]])
      player.stubs(:seat).returns(seat)      
      player.stubs(:chip_stack).returns(INITIAL_STACK_SIZE)
      player.stubs(:active?).returns(true)
      
      player
   end
   def init_actions_taken_in_current_round(number_of_players)
      @actions_taken_this_hand = []
      number_of_players.times do |i|
         player_list = []
         @actions_taken_this_hand << [player_list]
      end
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
   def setup_actions_taken_this_hand!(players, index_of_player_who_acted_last,
                                            round, action)
      actions_taken_this_hand_before_action_is_taken = []
      @actions_taken_this_hand.each_index do |i|
         actions_taken_this_hand_before_action_is_taken << []
         @actions_taken_this_hand[i].each do |current_action|
            actions_taken_this_hand_before_action_is_taken[i] << current_action.dup
         end
            
         players[i].stubs(:actions_taken_this_hand).returns(actions_taken_this_hand_before_action_is_taken[i])
      end
      
      @actions_taken_this_hand[index_of_player_who_acted_last][round] << action
      
      action_appended = states('action_appended').starts_as('no')
      players[index_of_player_who_acted_last].expects(:take_action!).with(action).then(action_appended.is('yes'))
      players.each_index do |i|
         players[i].stubs(:actions_taken_this_hand).returns(
            @actions_taken_this_hand[i]
         ).when(action_appended.is('yes'))
      end
   end
   def check_patient(then_values)
      @patient.players.should == then_values.players
      @patient.player_acting_sequence.should == then_values.player_acting_sequence
      @patient.number_of_players.should == then_values.number_of_players
      @patient.player_who_acted_last.should == then_values.player_who_acted_last
      @patient.next_player_to_act.should == then_values.next_player_to_act
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