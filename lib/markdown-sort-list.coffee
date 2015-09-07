{CompositeDisposable} = require 'atom'

module.exports =
  activate: ->
    atom.commands.add 'atom-workspace',
      'markdown-sort-list:convert': => @convert()

  convert: ->
    marked = require 'marked'

    editor = atom.workspace.getActivePaneItem()
    selection = editor.getLastSelection()
    tokens = marked.lexer selection.getText()

    ###*
     * Sorts list of objects by "text" field
    ###
    sortList = (list) ->
      list.sort (a,b) ->
        return if a.text.toUpperCase() >= b.text.toUpperCase() then 1 else -1
      return list

    ###*
     * Returns sorted list block of marked tokens
     * @param  {Number} start [the beginning index for the list block]
     * @return {[ [Object], Number ]} [an object containing list item data and ending index of list block]
    ###
    blockList = (start) ->
      listItems = []
      j = start

      while j < tokens.length-1
        j++

        if tokens[j].type is 'list_item_start'

          if tokens[j+2].type is 'list_start' and tokens[j+2].ordered is false
            [subList, end] = blockList j
            listItems.push {
              text: tokens[j+1].text
              items: subList
            }
            j = end

          else
            listItems.push {
              text: tokens[j+1].text
            }

        else if tokens[j].type is 'list_end'
          break

      sortedList = sortList listItems
      return [sortedList, j]

    ###*
     * Converts tree of list items to markdown string
     * @param  {Object} item   [item of list]
     * @param  {Number} indent [indent level integer]
     * @return {null}
    ###
    stringifyList = (item, indent) ->
      # Sets indentation tabs
      space = ""
      for i in [0...indent]
        space += "\t"

      # Recursively adds to outputText
      outputText += space+"* "+item.text+"\n"
      if item.items
        stringifyList item, indent+1 for item in item.items

      return

    outputText = ""

    # Set initial starting index for a markdown list
    for token, i in tokens
      if token.type is "list_start" and token.ordered is false
        [listTree, end] = blockList i

        for item in listTree
          stringifyList item, 0

        break

    editor.insertText outputText
