
# Local modules
require File.expand_path('../acpc_poker_match_state_defs', __FILE__)

# Gems
require 'acpc_poker_types'

class MatchStateTransition

   attr_accessor :next_state
   
   attr_reader :last_state
      
   # @param [Integer] last_round The round in which the last action was taken.
   # @return [Boolean] +true+ if the current round is a later round than the
   #  round in which the last action was taken, +false+ otherwise.
   def new_round?
      initial_round? || @next_state.round > @last_state.round
   end
   
   def initial_round?
      @last_state.first_state_of_first_round?
   end
   
   def complete_transition!
      @last_state = @next_state
   end
end
