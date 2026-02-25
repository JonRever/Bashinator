# shellcheck shell=bash
# bashinator version 0.1.3

IsEmpty()
{
    local value="$1"
    
	if [[ -z $value ]]
    then
        return 0
    else
        return 1
    fi
}

IsNull()
{
    local value="$1"

    if [[ "$value" = "null" ]]
    then
        return 0
    else
        return 1
    fi
}

IsBoolean()
{
    local value="$1"
    if [[ "$value" = "true" ]] || [[ "$value" = "false" ]]
    then
        return 0
    else
        return 1
    fi
}

IsString()
{
    local value="$1"
    
    if [[ "$value" =~ [[:alpha:]] ]]
    then
        return 0
    else
        return 1
    fi
}

IsInteger()
{
    local value="$1"

    if [[ "$value" =~ ^-?[0-9]+$ ]]
	then
		return 0
	fi

    return 1
}

IsPositiveInteger()
{
    local value="$1"

	if ! IsInteger "$value"
	then
		return 1
    fi

    if [[ $value -le 0 ]]
    then
        return 1
    else
        return 0
    fi
}

IsGreaterZero()
{
	local value="$1"

	if ! IsInteger "$value"
	then
		return 1
    fi

    if [[ $value -lt 0 ]]
    then
        return 1
    else
        return 0
    fi
}

IsIPv4()
{
    local ip="$1"

	if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
	then
        local -a octets

        IFS='.' readarray -t octets <<< "$ip"

		for octet in "${octets[@]}"
		do
            if [[ $octet -le 255 ]]
            then
                continue
            else
                return 1
            fi
        done

        return 0
	else
		return 1
    fi
}

IsIPv6() 
{
    local ip="$1"
    
	if [[ $ip =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]
    then
        return 0
    else
        return 1
    fi
}

IsIPv4CIDR() 
{
    local cidr="$1"
    local ip
    
	if [[ $cidr =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/(0|[1-9]|[12][0-9]|3[0-2])$ ]]
    then
        ip="${cidr%%/*}"

        if ! IsIPv4 "$ip"
        then
            return 1
        fi

        return 0
    fi
        
    return 1
}

IsUUID() 
{
    local value="$1"
    
	if [[ $value =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]
    then
        return 0
    else
        return 1
    fi
}

IsBase64() 
{
    local value="$1"
    
    if [[ $value =~ ^[A-Za-z0-9+/]*={0,2}$ ]]
    then
        return 0
    else
        return 1
    fi
}

IsDate() 
{
    local value="$1"
    
	if [[ $value =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
	then
        return 0
    else
        return 1
    fi
}

IsEnum() 
{
    local value="$1"
    local valid_values valid
    shift
    valid_values=("$@")
    
    for valid in "${valid_values[@]}"
	do
        if [[ "$value" = "$valid" ]]
        then
            return 0
        fi
    done
    
	return 1
}

ContainsDangerousChars() 
{
    local InputText="$1"
    
    if IsEmpty "$InputText"
    then
        return 1
    fi
    
    # check for shell injection
    if [[ "$InputText" =~ [\<\>\&\`\$\;\\] ]] 
	then
        return 0  # contains dangerous characters
    else
        return 1  # safe
    fi
}

# check for only safe characters
IsSafeText() 
{
    local InputText="$1"
    local max_length="${2:-255}"
    
    if IsEmpty "$InputText"
    then
        return 1
    fi
    
    # check the length
    if [[ ${#InputText} -gt $max_length ]]
	then
        return 1
    fi
    
    # check for dangerous characters
    if ContainsDangerousChars "$InputText"
	then
        return 1
    fi
    
    return 0  # text is safe
}

# check for empty string or only spaces
IsEmptyOrWhitespace() 
{
    local InputText="$1"
    
    if IsEmpty "$InputText"
    then
        return 1
    fi
    
    # check for only spaces
    if [[ $InputText =~ ^[[:space:]]*$ ]]
	then
        return 0  # only spaces
    else
        return 1  # contains text
    fi
}

IsValueInArray()
{
	local value="$1"
	local -n array="$2"
    local item  
	
    for item in "${array[@]}"
    do
        if [[ "$value" == "$item" ]]
        then
            return 0
        fi
    done
    return 1
}

IsJSON()
{   
    local JsonInput="$1"
    local -a TokensArray
    local IndexRight IndexLeft TokenString

    tokenise_json()
    {
        local json_input="$1"
        local json_tokenised json_safe json_raw
        
        json_raw=$(sed 's/\\"/\x01/g; s/"[^"]*"/some_val/g' <<< "$json_input")

        json_safe=$(sed -E 's/null/value/g; s/true/value/g; s/false/value/g; s/-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?/value/g;' <<< "$json_raw")
        
        json_tokenised=$(sed 's/:/ : /g; s/[,]/ , /g; s/[{]/ { /g; s/[}]/ } /g; s/\[/ [ /g; s/\]/ ] /g; s/some_val/ some_val /g; s/value/ value /g; s/ \+/ /g' <<< "$json_safe")

        printf '%s' "$json_tokenised"
    }

    normalize_token_types()
    {
        local -n ArrayName="$1"
        local Index LastIndex NextToken
        
        LastIndex=$(( ${#ArrayName[@]} - 1 ))

        for (( Index=0; Index<=LastIndex; Index++ ))
        do
            if [[ "${ArrayName[Index]}" == "some_val" ]]
            then
                NextToken="${ArrayName[Index+1]}"
                
                if [[ "$NextToken" == ":" ]]
                then

                    ArrayName[Index]='key'
                else
                    ArrayName[Index]='value'
                fi
            fi
        done
    }

    found_correspondence()
    {
        local -n arr_ref="$1"
        local index="$2"
        local expected_token="$3"
        local shift_mode="$4"
        local max_index min_index

        max_index=$(( ${#arr_ref[@]} - 1 ))
        min_index=0

        case "$shift_mode" in
            'right')
                until [[ $expected_token == "${arr_ref[$index]}" ]]
                do
                    index=$(( index + 1 ))
                    if [[ $index -gt $max_index ]]
                    then
                        return 1
                    fi
                done

                printf '%s' "$index"

            ;;
            'left')
                until [[ $expected_token == "${arr_ref[$index]}" ]]
                do
                    index=$(( index - 1 ))
                    if [[ $index -lt $min_index ]]
                    then
                        return 1
                    fi
                done

                printf '%s' "$index"
            ;;
        esac

        return 0
    }

    expected_map()
    {
        local token="$1"
        local next_token="$2"
        
        case "$token" in
            'key')
                case "$next_token" in
                    ':')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            ':')
                case "$next_token" in
                    'value')
                        return 0
                    ;;
                    '{' | 'opening_curly_brace')
                        return 0
                    ;;
                    '[' | 'opening_square_bracket')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            '{' | 'opening_curly_brace')
                case "$next_token" in
                    'key')
                        return 0
                    ;;
                    '}' | 'closing_curly_brace')
                        return 0
                    ;;

                    *)
                        return 1
                    ;;
                esac
            ;;
            '[' | 'opening_square_bracket')
                case "$next_token" in
                    'value')
                        return 0
                    ;;
                    '{' | 'opening_curly_brace')
                        return 0
                    ;;
                    '[' | 'opening_square_bracket')
                        return 0
                    ;;
                    ']' | 'closing_square_bracket')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            'value')
                case "$next_token" in
                    ',')
                        return 0
                    ;;
                    '}' | 'closing_curly_brace')
                        return 0
                    ;;
                    ']' | 'closing_square_bracket')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            ']' | 'closing_square_bracket')
                case "$next_token" in
                    ',')
                        return 0
                    ;;
                    '}' | 'closing_curly_brace')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            '}' | 'closing_curly_brace')
                case "$next_token" in
                    ',')
                        return 0
                    ;;
                    '}' | 'closing_curly_brace')
                        return 0
                    ;;
                    ']' | 'closing_square_bracket')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            ',')
                case "$next_token" in
                    'key')
                        return 0
                    ;;
                    '{' | 'opening_curly_brace')
                        return 0
                    ;;
                    'value')
                        return 0
                    ;;
                    '[' | 'opening_square_bracket')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            *)
                return 1
            ;;
        esac
    }

    expected_map_reverse()
    {
        local token="$1"
        local next_token="$2"

        
        case "$token" in
            'key')
                case "$next_token" in
                    ',')
                        return 0
                    ;;
                    '{' | 'opening_curly_brace')
                        return 0
                    ;;
                    *)
                        return 1
                esac
            ;;
            ':')
                case "$next_token" in
                    'key')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            '{' | 'opening_curly_brace')
                case "$next_token" in
                    ',')
                        return 0
                    ;;
                    ':')
                        return 0
                    ;;
                    '[' | 'opening_square_bracket')
                        return 0
                    ;;
                    *)
                        return 1
                esac
            ;;
            '[' | 'opening_square_bracket')
                case "$next_token" in
                    ':')
                        return 0
                    ;;
                    '[' | 'opening_square_bracket')
                        return 0
                    ;;
                    ',')
                        return 0
                    ;;
                    *)
                        return 1
                esac
            ;;
            'value')
                case "$next_token" in
                    '[' | 'opening_square_bracket')
                        return 0
                    ;;
                    ':')
                        return 0
                    ;;
                    ',')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            ']' | 'closing_square_bracket')
                case "$next_token" in
                    'value')
                        return 0
                    ;;
                    '[' | 'opening_square_bracket')
                        return 0
                    ;;
                    '}' | 'closing_curly_brace')
                        return 0
                    ;;
                    ']' | 'closing_square_bracket')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            '}' | 'closing_curly_brace')
                case "$next_token" in
                    'value')
                        return 0
                    ;;
                    '}' | 'closing_curly_brace')
                        return 0
                    ;;
                    ']' | 'closing_square_bracket')
                        return 0
                    ;;
                    '{' | 'opening_curly_brace')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            ',')
                case "$next_token" in
                    'value')
                        return 0
                    ;;
                    '}' | 'closing_curly_brace')
                        return 0
                    ;;
                    ']' | 'closing_square_bracket')
                        return 0
                    ;;
                    *)
                        return 1
                    ;;
                esac
            ;;
            *)
                return 1
            ;;
        esac
    }

    check_next_token()
    {
        local -n array="$1"
        local index="$2"
        local check_mode="$3"
        local token
        local -a ArrayToCheck

        ArrayToCheck=("${array[@]}")

        token="${ArrayToCheck[index]}"

        case "$check_mode" in
            'right')
                next_token="${ArrayToCheck[index + 1]}"
                if ! expected_map "$token" "$next_token"
                then
                    return 1
                fi
            ;;
            'left')
                next_token="${ArrayToCheck[index - 1]}"
                if ! expected_map_reverse "$token" "$next_token"
                then
                    return 1
                fi
            ;;
        esac

    }

    check_json_structure()
    {
        local -n array_name="$1"
        local IndexRight="$2"
        local IndexLeft="$3"
        local TokenRight TokenLeft expected_token replecement_token_left replecement_token_right CorrespondedIndex

        while (( IndexLeft <= IndexRight ))
        do
            TokenRight="${array_name[IndexRight]}"
            TokenLeft="${array_name[IndexLeft]}"

            case "$TokenRight" in
                '{'|'['|'}'|']')
                    if ! check_next_token array_name "$IndexRight" 'left'
                    then
                        Log -e 'Invalid next token'
                        return 1
                    fi

                    case "$TokenRight" in
                        '{')
                            expected_token='}'
                            replecement_token_left='closing_curly_brace'
                            replecement_token_right='opening_curly_brace'
                        ;;
                        '}')
                            expected_token='{'
                            replecement_token_left='opening_curly_brace'
                            replecement_token_right='closing_curly_brace'
                        ;;
                        ']')
                            expected_token='['
                            replecement_token_left='opening_square_bracket'
                            replecement_token_right='closing_square_bracket'
                        ;;
                        '[')
                            expected_token=']'
                            replecement_token_left='closing_square_bracket'
                            replecement_token_right='opening_square_bracket'
                        ;;
                    esac

                    Log -d "Expected token: $expected_token"
                    Log -d "Replacemnt token left: $replecement_token_left"
                    Log -d "Replacemnt token right: $replecement_token_right"
                    Log -d "Index left: $IndexLeft"
                    Log -d "Index right: $IndexRight"
                    Log -d "Token array: ${array_name[*]}"

                    Log -d 'Finding corresponding index...'

                    CorrespondedIndex=$(found_correspondence array_name "$IndexLeft" "$expected_token" 'right')

                    if IsEmpty "$CorrespondedIndex"
                    then
                        Log -e 'No corresponding index found'
                        return 1
                    fi
                    
                    array_name[CorrespondedIndex]="$replecement_token_left"
                    array_name[IndexRight]="$replecement_token_right"

                    unset expected_token replecement_token_left replecement_token_right CorrespondedIndex
                ;;
                *)
                    if ! check_next_token array_name "$IndexRight" 'left'
                    then
                        Log -e 'Invalid next token'
                        return 1
                    fi
                ;;
            esac

            TokenRight="${array_name[IndexRight]}"
            TokenLeft="${array_name[IndexLeft]}"

            case "$TokenLeft" in
                '{'|'['|'}'|']')
                    if ! check_next_token array_name "$IndexLeft" 'right'
                    then
                        Log -e 'Invalid next token'
                        return 1
                    fi

                    case "$TokenLeft" in
                        '{')
                            expected_token='}'
                            replecement_token_left='opening_curly_brace'
                            replecement_token_right='closing_curly_brace'
                        ;;
                        '}')
                            expected_token='{'
                            replecement_token_left='closing_curly_brace'
                            replecement_token_right='opening_curly_brace'
                        ;;
                        ']')
                            expected_token='['
                            replecement_token_left='closing_square_bracket'
                            replecement_token_right='opening_square_bracket'
                        ;;
                        '[')
                            expected_token=']'
                            replecement_token_left='opening_square_bracket'
                            replecement_token_right='closing_square_bracket'
                        ;;
                    esac

                    Log -d "Expected token: $expected_token"
                    Log -d "Index left: $IndexLeft"
                    Log -d "Index right: $IndexRight"
                    Log -d "Token array: ${array_name[*]}"

                    Log -d 'Finding corresponding index...'

                    CorrespondedIndex=$(found_correspondence array_name "$IndexRight" "$expected_token" 'left')

                    if IsEmpty "$CorrespondedIndex"
                    then
                        Log -e 'No corresponding index found'
                        return 1
                    fi

                    array_name[IndexLeft]="$replecement_token_left"
                    array_name[CorrespondedIndex]="$replecement_token_right"
                    
                    unset expected_token replecement_token_left replecement_token_right CorrespondedIndex
                ;;
                *)
                    if ! check_next_token array_name "$IndexLeft" 'right'
                    then
                        Log -e 'Invalid next token'
                        return 1
                    fi
                ;;
            esac

            IndexRight=$(( IndexRight - 1 ))
            IndexLeft=$(( IndexLeft + 1 ))

        done

        Log -d 'JSON structure is valid'
        return 0
    }
    
    if IsEmpty "$JsonInput"
    then
        Log -e 'Empty JSON input'
        return 1
    fi

    Log -d "JSON input: $JsonInput"

    Log -d 'Tokenising JSON input...'

    TokenString=$(tokenise_json "$JsonInput")

    Log -d "Tokenised JSON: $TokenString"

    IFS=' ' read -r -a TokensArray <<< "$TokenString"

    IndexLeft=0
    IndexRight=$(( ${#TokensArray[@]} - 1 ))

    Log -d 'Normalizing token types...'

    normalize_token_types TokensArray

    if (( ${#TokensArray[@]} == 1 )) && [[ "${TokensArray[$IndexLeft]}" == "value" ]]
    then
        Log -d 'Single value JSON input'
        return 0
    fi

    if [[ "${TokensArray[$IndexLeft]}" != "value" && "${TokensArray[$IndexLeft]}" != "{" && "${TokensArray[$IndexLeft]}" != "[" ]]
    then
        Log -e 'Invalid JSON input'
        return 1
    fi

    if ! check_json_structure TokensArray "$IndexRight" "$IndexLeft"
    then
        Log -e 'Invalid JSON structure'
        return 1
    fi

    Log -i 'Valid JSON input'
    return 0
}

WhatIs()
{
    local value="$1"
    local type

    if IsNull "$value"
    then
        type='null'
    elif IsBoolean "$value"
    then
        type='boolean'
    elif IsInteger "$value"
    then
        type='integer'
    elif IsPositiveInteger "$value"
    then
        type='integer'
    elif IsGreaterZero "$value"
    then
        type='integer'
    elif IsIPv4 "$value"
    then
        type='ipv4'
    elif IsIPv6 "$value"
    then
        type='ipv6'
    elif IsCidr "$value"
    then
        type='cidr'
    elif IsUUID "$value"
    then
        type='uuid'
    elif IsBase64 "$value"
    then
        type='base64'
    elif IsDate "$value"
    then
        type='date'
    elif IsString "$value"
    then
        type='string'
    fi

    if [[ -z $type ]]
    then
        type='string'
    fi

    printf '%s' "$type"
}