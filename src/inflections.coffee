inflect = require('inflect')

(->

  # Register exceptions
  # http://msnexploder.github.com/inflect/source/inflections.html
  inflect.inflections (inflections) ->

    inflections.plural   '12oz bag per week', '12oz bags per week'
    inflections.plural   'bento', 'bento'
    inflections.plural   'biscuits', 'biscuits'
    inflections.plural   'bottle per day', 'bottles per day'
    inflections.plural   'brioche', 'brioches'
    inflections.plural   'briochette', 'briochettes'
    inflections.plural   'carafe', 'carafes'
    inflections.plural   'dozen', 'dozen'
    inflections.plural   'dozen per week', 'dozen per week'
    inflections.plural   'foccacia', 'foccacias'
    inflections.plural   'full set of meals for next week', 'full sets of meals for next week'
    inflections.plural   'jar per month', 'jars per month'
    inflections.plural   'loaf', 'loaves'
    inflections.plural   'loaf per week', 'loaves per week'
    inflections.plural   'muffin per week', 'muffins per week'
    inflections.plural   'oz', 'oz'
    inflections.plural   'pie per week', 'pies per week '
    inflections.plural   'quiche', 'quiches'
    inflections.plural   'slice', 'slices'
    inflections.plural   'slices', 'slices'
    inflections.plural   'soup', 'soup'
    inflections.plural   'each', 'each'

    inflections.singular '2 cookies', '2 cookies'
    inflections.singular '3 cookies', '3 cookies'
    inflections.singular 'brownies', 'brownie'
    inflections.singular 'class', 'class'
    inflections.singular 'foccacia', 'foccacia'
    inflections.singular 'glass', 'glass'
    inflections.singular 'loaves', 'loaf'
    inflections.singular 'slice', 'slice'

  # Memoize
  singulars = {}
  plurals = {}
  pluralizeWithNumber = (str, num) ->
    if num? and 0 < parseFloat(num) <= 1
      singulars[str] ?= inflect.singularize(str)
      return singulars[str]
    else
      plurals[str] ?= inflect.pluralize(str)
      return plurals[str]

  nameize = (str) ->
    boundary = /\W+/g
    [matches, separators] = [str.split(boundary), str.match(boundary)]
    ret = [inflect.capitalize(matches[0])]
    if separators
      for separator, idx in separators
        ret[2 * idx + 1] = separator
        ret[2 * idx + 2] = inflect.capitalize(matches[idx + 1])
    return ret.join('')

  module.exports =
    camelize: inflect.camelize
    underscore: inflect.underscore
    dasherize: inflect.dasherize
    titleize: inflect.titleize
    capitalize: inflect.capitalize
    pluralize: pluralizeWithNumber
    singularize: inflect.singularize
    humanize: inflect.humanize
    ordinalize: inflect.ordinalize
    parameterize: inflect.parameterize
    nameize: nameize
)()
