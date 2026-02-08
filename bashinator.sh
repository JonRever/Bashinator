# shellcheck shell=bash
# bashinator version 0.1.0

IsEmpty()
{
    local value="$1"
    
	if [[ -z $value ]]
    then
		unset value
        return 0
    else
		unset value
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
        unset value
        return 0
    else
        unset value
        return 1
    fi
}

IsInteger()
{
    local value="$1"

    if [[ "$value" =~ ^-?[0-9]+$ ]]
	then
		unset value
		return 0
	fi

    unset value
    return 1
}

IsPositiveInteger()
{
    local value="$1"

	if ! IsInteger "$value"
	then
		unset value
		return 1
    fi

    if [[ $value -le 0 ]]
    then
		unset value
        return 1
    else
		unset value
        return 0
    fi
}

IsGreaterZero()
{
	local value="$1"

	if ! IsInteger "$value"
	then
		unset value
		return 1
    fi

    if [[ $value -lt 0 ]]
    then
		unset value
        return 1
    else
		unset value
        return 0
    fi
}

IsIPv4()
{
    local ip="$1"

	if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
	then
		local IFS='.'
        local -a octets=("$ip")
        
		for octet in "${octets[@]}"
		do
            if [[ $octet -le 255 ]]
            then
                :
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

IsCidr() 
{
    local cidr="$1"
    
	if [[ $cidr =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]
    then
        return 0
    else
        return 1
    fi
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
