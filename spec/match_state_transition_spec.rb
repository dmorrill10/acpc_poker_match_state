
require File.expand_path('../support/spec_helper', __FILE__)

require File.expand_path('../../lib/acpc_poker_match_state/match_state_transition', __FILE__)

describe MatchStateTransition do
   
   before(:each) do
      @patient = MatchStateTransition.new
   end
   
   it 'works when given an initial round' do
      check_initial_state
   end
   it 'works when given the same round' do
      prev_example = check_initial_state
      
      example = TestExample.new 'same round',
         {given: [:next_state],
          then: [:next_state, :is_new_round, :last_state, :is_initial_round]}
      
      example.then.last_state = prev_example.then.next_state
      example.then.last_state.stubs(:round).returns(0)
      
      example.given.next_state = mock 'MatchStateString'
      example.given.next_state.stubs(:round).returns(0)
      example.given.next_state.stubs(:first_state_of_first_round?).returns(false)
      
      example.then.next_state = example.given.next_state
      
      example.then.is_new_round = false
      example.then.is_initial_round = false
      
      @patient.next_state = example.given.next_state
      
      check_patient example.then
   end
   it 'works when given the next round' do
      prev_example = check_initial_state
      
      example = TestExample.new 'next round',
         {given: [:next_state],
          then: [:next_state, :is_new_round, :last_state, :is_initial_round]}
      
      example.then.last_state = prev_example.then.next_state
      example.then.last_state.stubs(:round).returns(0)
      
      example.given.next_state = mock 'MatchStateString'
      example.given.next_state.stubs(:round).returns(1)
      example.given.next_state.stubs(:first_state_of_first_round?).returns(false)
      
      example.then.next_state = example.given.next_state
      
      example.then.is_new_round = true
      example.then.is_initial_round = false
      
      @patient.next_state = example.given.next_state
      
      check_patient example.then
   end
   describe 'works when given a new first round' do
      it 'when starting in round zero' do
         prev_example = check_initial_state
         
         example = TestExample.new 'new first round',
            {given: [:next_state],
             then: [:next_state, :is_new_round, :last_state, :is_initial_round]}
         
         example.then.last_state = prev_example.then.next_state
         example.then.last_state.stubs(:round).returns(0)
         
         example.given.next_state = mock 'MatchStateString'
         example.given.next_state.stubs(:round).returns(0)
         example.given.next_state.stubs(:first_state_of_first_round?).returns(true)
         
         example.then.next_state = example.given.next_state
         
         example.then.is_new_round = true
         example.then.is_initial_round = true
         
         @patient.next_state = example.given.next_state
         
         check_patient example.then
      end
      it 'when starting in a later round' do
         prev_example = check_initial_state
         
         example = TestExample.new 'new first round',
            {given: [:next_state],
             then: [:next_state, :is_new_round, :last_state, :is_initial_round]}
         
         example.then.last_state = prev_example.then.next_state
         example.then.last_state.stubs(:round).returns(1)
         
         example.given.next_state = mock 'MatchStateString'
         example.given.next_state.stubs(:round).returns(0)
         example.given.next_state.stubs(:first_state_of_first_round?).returns(true)
         
         example.then.next_state = example.given.next_state
         
         example.then.is_new_round = true
         example.then.is_initial_round = true
         
         @patient.next_state = example.given.next_state
         
         check_patient example.then
      end
   end
   
   def check_initial_state
      example = TestExample.new 'initial state',
         {given: [:next_state],
          then: [:next_state, :is_new_round, :last_state, :is_initial_round]}
      
      example.given.next_state = mock 'MatchStateString'
      example.given.next_state.stubs(:first_state_of_first_round?).returns(true)
      
      example.then.is_new_round = true
      example.then.last_state = nil
      example.then.is_initial_round = true
      example.then.next_state = example.given.next_state
      
      @patient.next_state = example.given.next_state
      
      check_patient example.then
      
      example
   end
   def check_patient(expected)
      @patient.next_state.should == expected.next_state
      @patient.new_round?.should == expected.is_new_round
      @patient.last_state.should == expected.last_state
      @patient.initial_round?.should == expected.is_initial_round
   end
end
