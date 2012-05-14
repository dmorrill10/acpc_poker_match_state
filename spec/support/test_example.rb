
class Symbol
   def to_setter_signature
      "#{self}=".to_sym
   end
end

require 'acpc_poker_types/mixins/utils'

class TestExample
   
   exceptions :no_properties_for_given, :no_properties_for_then
   
   attr_reader :description, :given, :then
   
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
