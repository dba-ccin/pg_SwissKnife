/*

Luhn algorithm implementation for PostgreSQL with basic input check.
Based on Craig Ringer script - https://wiki.postgresql.org/wiki/Luhn_algorithm

Haptomai - haptomai@gmail.com

License : 

*/

CREATE OR REPLACE FUNCTION luhn_verify(int8)
    RETURNS BOOLEAN AS
$$
    -- Take the sum of the doubled digits and the even-numbered undoubled digits,
    -- and see if the sum is evenly divisible by zero.

    DECLARE
        response boolean;

    BEGIN
        CASE
            WHEN $1::text ~ '[^0-9]' THEN RETURN FALSE;
                -- If the passed parameter contains anything other than digits, return false
            ELSE

                SELECT into response
                         -- Doubled digits might in turn be two digits. In that case,
                         -- we must add each digit individually rather than adding the
                         -- doubled digit value to the sum. Ie if the original digit was
                         -- `6' the doubled result was `12' and we must add `1+2' to the
                         -- sum rather than `12'.
                         MOD(SUM(doubled_digit / INT8 '10' + doubled_digit % INT8 '10'), 10) = 0
                FROM
                -- Double odd-numbered digits (counting left with
                -- least significant as zero). If the doubled digits end up
                -- having values
                -- > 10 (ie they're two digits), add their digits together.
                (SELECT
                         -- Extract digit `n' counting left from least significant
                         -- as zero
                         MOD( ( $1::int8 / (10^n)::int8 ), 10::int8)
                         -- Double odd-numbered digits
                         * (MOD(n,2) + 1)
                         AS doubled_digit
                         FROM generate_series(0, CEIL(LOG( $1 ))::INTEGER - 1) AS n
                ) AS doubled_digits;

                RETURN response;

         END CASE;
    END;

$$
  LANGUAGE plpgsql IMMUTABLE STRICT;

COMMENT ON FUNCTION luhn_verify(int8) IS 'Return true if the last digit of the
input is a correct check digit for the rest of the input according to Luhn''s
algorithm.';

