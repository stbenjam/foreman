module ApiExtensions
  extend ActiveSupport::Concern

  module ClassMethods
    def add_attribute(attribute, type, options = {})
      @extended_attributes ||= []
      @extended_attributes << {:name => attribute, :type => type, :options => options}
    end

    def extended_attributes
      @extended_attributes || []
    end

    def extended_rabl_attributes
      @extended_attributes.map { |attr| attr[:name] }
    end
  end
end
