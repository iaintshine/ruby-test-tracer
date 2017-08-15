module Test
  module TypeCheck
    class NullError < StandardError; end

    def Type?(value, *types)
      types.any? { |t| value.is_a? t }
    end

    def Type!(value, *types)
      Type?(value, *types) or
        raise TypeError, "Value (#{value.class}) '#{value}' is not any of: #{types.join('; ')}."
      value
    end

    def NotNull!(value)
      raise NullError, "Value must not be nil" unless value
    end

    def Argument!(expression, message = "Illegal argument")
      raise ArgumentError, message unless expression
    end
  end
end
