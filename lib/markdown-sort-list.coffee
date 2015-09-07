{CompositeDisposable} = require 'atom'

module.exports =
  activate: ->
    # @convert()
    # @subscriptions = new CompositeDisposable
    # @subscriptions.add atom.commands.add 'atom-workspace',
    #   'markdown-sort-list:convert': => @convert()
    atom.commands.add 'atom-workspace',
      'markdown-sort-list:convert': => @convert()

  convert: ->
    console.log 'pls'
    editor = atom.workspace.getActivePaneItem()
    selection = editor.getLastSelection()

    marked = require 'marked'
    tokens = marked.lexer selection.getText()

    console.log tokens

    sortList = (list) ->
      console.log list
      list.sort (a,b) ->
        return if a.text.toUpperCase() >= b.text.toUpperCase() then 1 else -1
      return list

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

    outputText = ""
    stringifyList = (item, indent) ->
      space = ""
      for i in [0...indent]
        space += "\t"
      outputText += space+"* "+item.text+"\n"
      if item.items
        stringifyList item, indent+1 for item in item.items

    for token, i in tokens
      if token.type is "list_start" and token.ordered is false
        [listTree, end] = blockList i
        console.log listTree
        for item in listTree
          stringifyList item, 0
        break
    editor.insertText outputText
