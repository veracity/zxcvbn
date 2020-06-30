scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Use a few words, avoid common phrases"
      "No need for symbols, digits, or uppercase letters"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'Add another word or two. Uncommon words are better.'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'Please avoid using straight rows of keys'
        else
          'Short keyboard patterns are easy to guess'
        warning: warning
        suggestions: [
          'Use a longer keyboard pattern with more turns'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Please avoid repeating letters or words.'
        else
          'Please avoid repeating words and characters.'
        warning: warning
        suggestions: [
          'Avoid repeated words and characters'
        ]

      when 'sequence'
        warning: "Please avoid sequences of words or characters"
        suggestions: [
          'Avoid sequences'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Please avoid recent or common years"
          suggestions: [
            'Avoid recent years'
            'Avoid years that are associated with you'
          ]

      when 'date'
        warning: "You should avoid important dates and years"
        suggestions: [
          'Avoid dates and years that are associated with you'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'Please avoid using very common passwords'
        else if match.rank <= 100
          'Please avoid using very common passwords'
        else
          'Please avoid using very common passwords'
      else if match.guesses_log10 <= 4
        'Please avoid using very common passwords'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'Please avoid using a word by itself'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'Please avoid using names and surnames by themselves'
      else
        'Please avoid using common names and surnames'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Please avoid capitalization"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Please avoid using all-uppercase"

    if match.reversed and match.token.length >= 4
      suggestions.push "Please avoid using reversed words"
    if match.l33t
      suggestions.push "Please avoid using predictable substitutions for letters"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
