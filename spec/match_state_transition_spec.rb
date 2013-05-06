
require_relative 'support/spec_helper'

require 'acpc_poker_match_state/match_state_transition'

describe AcpcPokerMatchState::MatchStateTransition do

  before(:each) do
    @patient = AcpcPokerMatchState::MatchStateTransition.new
  end

  describe '#set_next_state!' do
    it 'assigns the new state to be the next state' do
      new_state = 'new match state'

      @patient.set_next_state! new_state
      @patient.next_state.must_equal new_state
    end
    it 'replaces the last state' do
      last_state = 'last match state'

      @patient.set_next_state! last_state
      @patient.last_state.must_equal nil
      @patient.next_state.must_equal last_state

      next_state = 'new match state'

      @patient.set_next_state! next_state
      @patient.last_state.must_equal last_state
      @patient.next_state.must_equal next_state
      @patient.last_state.wont_be_same_as next_state
    end
  end
  describe '#new_round?' do
    it 'raises an exception if it is called before #next_state!' do
      -> do
        @patient.new_round?
      end.must_raise(AcpcPokerMatchState::MatchStateTransition::NoStateGiven)
    end
    describe 'reports true' do
      it 'when given an initial state' do
        new_state = 'new match state'

        @patient.set_next_state!(new_state).new_round?.must_equal true
      end
      it 'when subsequently given a state with a later round' do
        initial_state = MiniTest::Mock.new
        initial_state.expect :round, 0

        @patient.set_next_state! initial_state

        new_state = MiniTest::Mock.new
        new_state.expect :round, 1

        @patient.set_next_state!(new_state).new_round?.must_equal true
      end
      it 'when subsequently given a state with an earlier round' do
        initial_state = MiniTest::Mock.new
        initial_state.expect :round, 1

        @patient.set_next_state! initial_state

        new_state = MiniTest::Mock.new
        new_state.expect :round, 0

        @patient.set_next_state!(new_state).new_round?.must_equal true
      end
    end
    it 'reports false when subsequently given a state with the same round' do
      initial_state = MiniTest::Mock.new
      initial_state.expect :round, 0

      @patient.set_next_state! initial_state

      new_state = MiniTest::Mock.new
      new_state.expect :round, 0

      @patient.set_next_state!(new_state).new_round?.must_equal false
    end
  end
  describe '#initial_state?' do
    it 'raises an exception if it is called before #next_state!' do
      -> do
        @patient.initial_state?
      end.must_raise(AcpcPokerMatchState::MatchStateTransition::NoStateGiven)
    end
    it 'reports true when given a state that reports it is the first ' +
    'state of the first round' do
      new_state = MiniTest::Mock.new
      new_state.expect :first_state_of_first_round?, true

      @patient.set_next_state!(new_state).initial_state?.must_equal true
    end
    it 'reports false when given a state that reports it is not the ' +
    'first state of the first round' do
      new_state = MiniTest::Mock.new
      new_state.expect :first_state_of_first_round?, false

      @patient.set_next_state!(new_state).initial_state?.must_equal false
    end
  end
end
