
require File.expand_path('../support/spec_helper', __FILE__)

require File.expand_path('../../lib/acpc_poker_match_state/match_state_transition', __FILE__)

describe MatchStateTransition do
   
   before(:each) do
      @patient = MatchStateTransition.new
   end
   
   describe '#set_next_state!' do
      it 'assigns the new state to be the next state' do
         new_state = mock 'MatchStateString'
            
         @patient.set_next_state! new_state
         @patient.next_state.should == new_state
      end
      it 'replaces the last state' do
         last_state = mock 'MatchStateString'
            
         @patient.set_next_state! last_state
         @patient.last_state.should == nil
         @patient.next_state.should == last_state
            
         next_state = mock 'MatchStateString'
            
         @patient.set_next_state! next_state
         @patient.last_state.should == last_state
         @patient.next_state.should == next_state
         @patient.last_state.should_not be next_state
      end
   end
   describe '#new_round?' do
      it 'raises an exception if it is called before #next_state!' do
         expect do
            @patient.new_round?
         end.to raise_exception(MatchStateTransition::NoStateGiven)
      end
      describe 'reports true' do
         it 'when given an initial state' do
            new_state = mock 'MatchStateString'
            
            @patient.set_next_state!(new_state).new_round?.should == true
         end
         it 'when subsequently given a state with a later round' do
            initial_state = mock 'MatchStateString'
            initial_state.stubs(:round).returns(0)
         
            @patient.set_next_state! initial_state
         
            new_state = mock 'MatchStateString'
            new_state.stubs(:round).returns(1)
         
            @patient.set_next_state!(new_state).new_round?.should == true
         end
         it 'when subsequently given a state with an earlier round' do
            initial_state = mock 'MatchStateString'
            initial_state.stubs(:round).returns(1)
         
            @patient.set_next_state! initial_state
         
            new_state = mock 'MatchStateString'
            new_state.stubs(:round).returns(0)
         
            @patient.set_next_state!(new_state).new_round?.should == true
         end
      end
      it 'reports false when subsequently given a state with the same round' do
         initial_state = mock 'MatchStateString'
         initial_state.stubs(:round).returns(0)
      
         @patient.set_next_state! initial_state
      
         new_state = mock 'MatchStateString'
         new_state.stubs(:round).returns(0)
      
         @patient.set_next_state!(new_state).new_round?.should == false
      end
   end
   describe '#initial_state?' do
      it 'raises an exception if it is called before #next_state!' do
         expect do
            @patient.initial_state?
         end.to raise_exception(MatchStateTransition::NoStateGiven)
      end
      it 'reports true when given a state that reports it is the first ' +
         'state of the first round' do
         new_state = mock 'MatchStateString'
         new_state.stubs(:first_state_of_first_round?).returns(true)
            
         @patient.set_next_state!(new_state).initial_state?.should == true
      end
      it 'reports false when given a state that reports it is not the ' +
         'first state of the first round' do
         new_state = mock 'MatchStateString'
         new_state.stubs(:first_state_of_first_round?).returns(false)
         
         @patient.set_next_state!(new_state).initial_state?.should == false
      end
   end
end