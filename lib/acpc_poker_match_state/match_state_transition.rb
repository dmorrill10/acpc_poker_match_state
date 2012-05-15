
# Local modules
require File.expand_path('../acpc_poker_match_state_defs', __FILE__)

# Gems
require 'acpc_poker_types'

class MatchStateTransition

   exceptions :no_state_given

   attr_reader :next_state
   
   attr_reader :last_state
   
   def next_state!(new_state)
      @next_state = new_state
      
      yield
      
      @last_state = @next_state
   end
   
   # @return [Boolean] +true+ if the next state's round is different from the
   #  last, +false+ otherwise.
   def new_round?
      raise NoStateGiven unless @next_state
      return true unless @last_state
      
      @next_state.round != @last_state.round
   end
   
   def initial_round?
      raise NoStateGiven unless @next_state
      
      @next_state.first_state_of_first_round?
   end
end
