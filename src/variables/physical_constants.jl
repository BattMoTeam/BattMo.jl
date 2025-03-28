export
    Constants
    
struct Constants
    F
    R
    hour
    function Constants()
        new(96485.3329,
            8.31446261815324,
            3600)
    end
end

con = Constants()
const FARADAY_CONSTANT = con.F
const GAS_CONSTANT = con.R

