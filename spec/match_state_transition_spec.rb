
require File.expand_path('../support/spec_helper', __FILE__)

require File.expand_path('../../lib/acpc_poker_match_state/match_state_transition', __FILE__)

describe MatchStateTransition do
   
   before(:each) do
      @patient = MatchStateTransition.new
   end
   
   describe '#next_state!' do
      describe 'assigns the new state to be the next state' do
         it 'during transition' do
            new_state = mock 'MatchStateString'
            
            @patient.next_state! new_state do
               @patient.next_state.should == new_state
            end
         end
         it 'after transition' do
            new_state = mock 'MatchStateString'
            
            @patient.next_state!(new_state) {}
            @patient.next_state.should == new_state
         end
      end
      describe 'replaces the last state' do
         it 'only after transition' do
            last_state = mock 'MatchStateString'
            
            @patient.next_state!(last_state) do
               @patient.last_state.should == nil
            end
            
            @patient.last_state.should == last_state
            @patient.next_state.should == last_state
            
            next_state = mock 'MatchStateString'
            
            @patient.next_state! next_state do
               @patient.last_state.should == last_state
               @patient.last_state.should_not be next_state
            end
            
            @patient.last_state.should == next_state
            @patient.next_state.should == next_state
         end
      end
   end
   describe '#new_round?' do
      it 'raises an exception if it is called before #next_state!' do
         expect do
            @patient.new_round?
         end.to raise_exception(MatchStateTransition::NoStateGiven)
      end
      describe 'when given an initial state' do
         it 'reports true while in transition' do
            new_state = mock 'MatchStateString'
            
            @patient.next_state! new_state do
               @patient.new_round?.should == true
            end
         end
         it 'reports false after transition' do
            new_state = mock 'MatchStateString'
            new_state.stubs(:round).returns(0)
      
            @patient.next_state!(new_state) {}
               
            @patient.new_round?.should == false
         end
      end
      describe 'when given a subsequent state' do
         describe 'reports false when the rounds are the same' do
            it 'during transition' do
               initial_state = mock 'MatchStateString'
               initial_state.stubs(:round).returns(0)
               
               @patient.next_state!(initial_state) {}
               
               new_state = mock 'MatchStateString'
               new_state.stubs(:round).returns(0)
               
               @patient.next_state!(new_state) do
                  @patient.new_round?.should == false
               end
            end
            it 'after transition' do
               initial_state = mock 'MatchStateString'
               initial_state.stubs(:round).returns(0)
               
               @patient.next_state!(initial_state) {}
               
               new_state = mock 'MatchStateString'
               new_state.stubs(:round).returns(0)
               
               @patient.next_state!(new_state) {}
               
               @patient.new_round?.should == false
            end
         end
         describe 'when the next round' do
            describe 'is later,' do
               it 'true is reported during transition' do
                  initial_state = mock 'MatchStateString'
                  initial_state.stubs(:round).returns(0)
               
                  @patient.next_state!(initial_state) {}
               
                  new_state = mock 'MatchStateString'
                  new_state.stubs(:round).returns(1)
               
                  @patient.next_state!(new_state) do
                     @patient.new_round?.should == true
                  end
               end
               it 'false is reported after transition' do
                  initial_state = mock 'MatchStateString'
                  initial_state.stubs(:round).returns(0)
               
                  @patient.next_state!(initial_state) {}
               
                  new_state = mock 'MatchStateString'
                  new_state.stubs(:round).returns(1)
               
                  @patient.next_state!(new_state) {}
               
                  @patient.new_round?.should == false
               end
            end
            describe 'is earlier,' do
               it 'true is reported during transition' do
                  initial_state = mock 'MatchStateString'
                  initial_state.stubs(:round).returns(1)
               
                  @patient.next_state!(initial_state) {}
               
                  new_state = mock 'MatchStateString'
                  new_state.stubs(:round).returns(0)
               
                  @patient.next_state!(new_state) do
                     @patient.new_round?.should == true
                  end
               end
               it 'false is reported after transition' do
                  initial_state = mock 'MatchStateString'
                  initial_state.stubs(:round).returns(1)
               
                  @patient.next_state!(initial_state) {}
               
                  new_state = mock 'MatchStateString'
                  new_state.stubs(:round).returns(0)
               
                  @patient.next_state!(new_state) {}
               
                  @patient.new_round?.should == false
               end
            end
         end
      end
   end
   describe '#initial_round?' do
      it 'raises an exception if it is called before #next_state!' do
         expect do
            @patient.initial_round?
         end.to raise_exception(MatchStateTransition::NoStateGiven)
      end
      describe 'reports true when given a state that reports it is the first ' +
         'state of the first round' do
      
         it 'while in transition' do
            new_state = mock 'MatchStateString'
            new_state.stubs(:first_state_of_first_round?).returns(true)
   
            @patient.next_state! new_state do
               @patient.initial_round?.should == true
            end
         end
         it 'after transition' do
            new_state = mock 'MatchStateString'
            new_state.stubs(:first_state_of_first_round?).returns(true)
            
            @patient.next_state!(new_state) {}
            
            @patient.initial_round?.should == true
         end
      end
      describe 'reports false when given a state that reports it is not the ' +
         'first state of the first round' do
      
         it 'while in transition' do
            new_state = mock 'MatchStateString'
            new_state.stubs(:first_state_of_first_round?).returns(false)
   
            @patient.next_state! new_state do
               @patient.initial_round?.should == false
            end
         end
         it 'after transition' do
            new_state = mock 'MatchStateString'
            new_state.stubs(:first_state_of_first_round?).returns(false)
            
            @patient.next_state!(new_state) {}
            
            @patient.initial_round?.should == false
         end
      end
   end
end