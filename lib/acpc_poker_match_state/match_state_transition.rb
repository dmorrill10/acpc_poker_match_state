require 'acpc_poker_types/match_state'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module AcpcPokerMatchState
  class MatchStateTransition
    exceptions :no_state_given

    attr_reader :next_state
    attr_reader :last_state

    def set_next_state!(new_state)
      @last_state = @next_state
      @next_state = new_state
      self
    end

    # @return [Boolean] +true+ if the next state's round is different from the
    #  last, +false+ otherwise.
    def new_round?
      raise NoStateGiven unless @next_state
      return true unless @last_state

      @next_state.round != @last_state.round
    end

    def initial_state?
      raise NoStateGiven unless @next_state

      @next_state.first_state_of_first_round?
    end
  end
end