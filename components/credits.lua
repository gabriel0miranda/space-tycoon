return function(amount)
    return {
        amount = amount or 0,
        add = function(self, value)
            self.amount = self.amount + value
        end,
        spend = function(self, value)
            if self.amount < value then return false, "Insufficient credits" end
            self.amount = self.amount - value
            return true
        end,
    }
end
