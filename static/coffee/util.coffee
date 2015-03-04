# Copyright 2010-2012 RethinkDB, all rights reserved.
# Prettifies a date given in Unix time (ms since epoch)

Handlebars = require('hbsfy/runtime');

# Returns a comma-separated list of the provided array
Handlebars.registerHelper 'comma_separated', (context, block) ->
    out = ""
    for i in [0...context.length]
        out += block context[i]
        out += ", " if i isnt context.length-1
    return out

# Returns a comma-separated list of the provided array without the need of a transformation
Handlebars.registerHelper 'comma_separated_simple', (context) ->
    out = ""
    for i in [0...context.length]
        out += context[i]
        out += ", " if i isnt context.length-1
    return out

# Returns a list to links to servers
Handlebars.registerHelper 'links_to_servers', (servers, safety) ->
    out = ""
    for i in [0...servers.length]
        if servers[i].exists
            out += '<a href="#servers/'+servers[i].id+'" class="links_to_other_view">'+servers[i].name+'</a>'
        else
            out += servers[i].name
        out += ", " if i isnt servers.length-1
    if safety? and safety is false
        return out
    return new Handlebars.SafeString(out)

#Returns a list of links to datacenters on one line
Handlebars.registerHelper 'links_to_datacenters_inline_for_replica', (datacenters) ->
    out = ""
    for i in [0...datacenters.length]
        out += '<strong>'+datacenters[i].name+'</strong>'
        out += ", " if i isnt datacenters.length-1
    return new Handlebars.SafeString(out)

# Helpers for pluralization of nouns and verbs
Handlebars.registerHelper 'pluralize_noun', (noun, num, capitalize) ->
    return 'NOUN_NULL' unless noun?
    ends_with_y = noun.substr(-1) is 'y'
    if num is 1
        result = noun
    else
        if ends_with_y and (noun isnt 'key')
            result = noun.slice(0, noun.length - 1) + "ies"
        else if noun.substr(-1) is 's'
            result = noun + "es"
        else if noun.substr(-1) is 'x'
            result = noun + "es"
        else
            result = noun + "s"
    if capitalize is true
        result = result.charAt(0).toUpperCase() + result.slice(1)
    return result

Handlebars.registerHelper 'pluralize_verb_to_have', (num) -> if num is 1 then 'has' else 'have'
Handlebars.registerHelper 'pluralize_verb', (verb, num) -> if num is 1 then verb+'s' else verb
#
# Helpers for capitalization
capitalize = (str) ->
    if str?
        str.charAt(0).toUpperCase() + str.slice(1)
    else
        "NULL"
Handlebars.registerHelper 'capitalize', capitalize

# Helpers for shortening uuids
Handlebars.registerHelper 'humanize_uuid', (str) ->
    if str?
        str.substr(0, 6)
    else
        "NULL"

# Helpers for printing connectivity
Handlebars.registerHelper 'humanize_server_connectivity', (status) ->
    if not status?
        status = 'N/A'
    success = if status == 'connected' then 'success' else 'failure'
    connectivity = "<span class='label label-#{success}'>#{capitalize(status)}</span>"
    return new Handlebars.SafeString(connectivity)

humanize_table_status = (status) ->
    if not status
        ""
    else if status.all_replicas_ready or status.ready_for_writes
        "Ready"
    else if status.ready_for_reads
        'Reads only'
    else if status.ready_for_outdated_reads
        'Outdated reads'
    else
        'Unavailable'

Handlebars.registerHelper 'humanize_table_readiness', (status, num, denom) ->
    if status is undefined
        label = 'failure'
        value = 'unknown'
    else if status.all_replicas_ready
        label = 'success'
        value = "#{humanize_table_status(status)} #{num}/#{denom}"
    else if status.ready_for_writes
        label = 'partial-success'
        value = "#{humanize_table_status(status)} #{num}/#{denom}"
    else
        label = 'failure'
        value = humanize_table_status(status)
    return new Handlebars.SafeString(
        "<div class='status label label-#{label}'>#{value}</div>")

Handlebars.registerHelper 'humanize_table_status', humanize_table_status

Handlebars.registerHelper 'approximate_count', (num) ->
    # 0 => 0
    # 1 - 5 => 5
    # 5 - 10 => 10
    # 11 - 99 => Rounded to _0
    # 100 - 999 => Rounded to _00
    # 1,000 - 9,999 => _._K
    # 10,000 - 10,000 => __K
    # 100,000 - 1,000,000 => __0K
    # Millions and billions have the same behavior as thousands
    # If num>1000B, then we just print the number of billions
    if num is 0
        return '0'
    else if num <= 5
        return '5'
    else if num <= 10
        return '10'
    else
        # Approximation to 2 significant digit
        approx = Math.round(num/Math.pow(10, num.toString().length-2)) *
            Math.pow(10, num.toString().length-2);
        if approx < 100 # We just want one digit
            return (Math.floor(approx/10)*10).toString()
        else if approx < 1000 # We just want one digit
            return (Math.floor(approx/100)*100).toString()
        else if approx < 1000000
            result = (approx/1000).toString()
            if result.length is 1 # In case we have 4 for 4000, we want 4.0
                result = result + '.0'
            return result+'K'
        else if approx < 1000000000
            result = (approx/1000000).toString()
            if result.length is 1 # In case we have 4 for 4000, we want 4.0
                result = result + '.0'
            return result+'M'
        else
            result = (approx/1000000000).toString()
            if result.length is 1 # In case we have 4 for 4000, we want 4.0
                result = result + '.0'
            return result+'B'

# Safe string
Handlebars.registerHelper 'print_safe', (str) ->
    if str?
        return new Handlebars.SafeString(str)
    else
        return ""

# Increment a number
Handlebars.registerHelper 'inc', (num) -> num + 1

# Register some useful partials
Handlebars.registerPartial 'backfill_progress_summary', $('#backfill_progress_summary-partial').html()
Handlebars.registerPartial 'backfill_progress_details', $('#backfill_progress_details-partial').html()

# if-like block to check whether a value is defined (i.e. not undefined).
Handlebars.registerHelper 'if_defined', (condition, options) ->
    if typeof condition != 'undefined' then return options.fn(this) else return options.inverse(this)

# Extract form data as an object
form_data_as_object = (form) ->
    formarray = form.serializeArray()
    formdata = {}
    for x in formarray
        formdata[x.name] = x.value
    return formdata


stripslashes = (str) ->
    str=str.replace(/\\'/g,'\'')
    str=str.replace(/\\"/g,'"')
    str=str.replace(/\\0/g,"\x00")
    str=str.replace(/\\\\/g,'\\')
    return str

is_integer = (data) ->
    return data.search(/^\d+$/) isnt -1

# Deep copy. We do not copy prototype.
deep_copy = (data) ->
    if typeof data is 'boolean' or typeof data is 'number' or typeof data is 'string' or typeof data is 'number' or data is null or data is undefined
        return data
    else if typeof data is 'object' and Object.prototype.toString.call(data) is '[object Array]'
        result = []
        for value in data
            result.push deep_copy value
        return result
    else if typeof data is 'object'
        result = {}
        for key, value of data
            result[key] = deep_copy value
        return result


exports.capitalize = capitalize
exports.humanize_table_status = humanize_table_status
exports.form_data_as_object = form_data_as_object
exports.stripslashes = stripslashes
exports.is_integer = is_integer
exports.deep_copy = deep_copy
