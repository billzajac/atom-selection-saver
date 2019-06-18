{CompositeDisposable} = require 'atom'

module.exports = SelectionSaver =
  subscriptions: null
  primaryPane: null
  primaryEditor: null
  primaryFile: null
  previousFile: null
  previousFileIsOpen: null
  manifestStream: null
  logPane: null
  logEditor: null
  logFileURI: "#{process.env.HOME}/selection-saver.#{process.env.USER}.log"

  activate: (state) ->
    # Assumption: A file with .manifest extension is open and is in focus
    # Find the open manifest file
    manifestPane = atom.workspace.getActivePane()
    manifestEditor = atom.workspace.getActiveTextEditor()
    manifestPath = manifestEditor.getPath()
    manifestCompletedPath = "#{manifestPath}.completed_files"
    manifestPane.destroy()

    atom.workspace.onDidDestroyPaneItem (event) ->
      # Check to see if the log file is still open by
      # first getting all of the paths of open editors
      # then checking to see if the log is in the array
      openFilePaths = atom.workspace.getTextEditors().map((e) ->
        e.getPath()
      )
      if SelectionSaver.previousFileIsOpen? && openFilePaths.indexOf(SelectionSaver.previousFile) == -1
        console.log("previousFile was Closed: #{SelectionSaver.previousFile}")
        # Set/Update the primaryPane and primaryEditor to this new file
        SelectionSaver.primaryPane = atom.workspace.getActivePane()
        SelectionSaver.primaryEditor = atom.workspace.getActiveTextEditor()
        SelectionSaver.previousFileIsOpen = null
      else if openFilePaths.indexOf(SelectionSaver.logFileURI) == -1
        console.log("logPane was Closed: #{SelectionSaver.logFileURI}")
      else if openFilePaths.indexOf(SelectionSaver.primaryFile) == -1
        console.log("File was Closed: #{SelectionSaver.primaryFile}")
        SelectionSaver.previousFile = SelectionSaver.primaryFile
        # Append to manifestCompletedPath file
        fs = require('fs')
        fs.appendFileSync(manifestCompletedPath, "#{SelectionSaver.primaryFile}\n")

        # DEBUG
        # atom.workspace.getPanes().map((p) ->
        #   console.log("PANE: ", p.isActive(), p.getActiveItem(), p.getItems(), p)
        # )

        console.log("Destroying primaryPane: #{SelectionSaver.primaryPane}")
        SelectionSaver.primaryPane.destroy() # if we hit crtl-w, we only destroyed the editor, not the pane
        SelectionSaver.logPane.destroy() # if we hit crtl-w, we only destroyed the editor, not the pane
        SelectionSaver.manifestStream.resume()

    atom.workspace.onDidOpen (event) ->
      if event.uri == SelectionSaver.logFileURI
        # The log file was opened, so update the logPane
        # console.log("logPane", SelectionSaver.logPane)       # DEBUG
        # console.log("logEditor", SelectionSaver.logEditor)   # DEBUG
        SelectionSaver.logPane = event.pane
        SelectionSaver.logEditor = event.item
        SelectionSaver.logEditor.scrollToBottom()
        return
      else
        # A new file was opened, so update the primaryPane
        console.log("Opened: ", event.uri)
        event.pane.activate()
        SelectionSaver.primaryPane = atom.workspace.getActivePane()
        SelectionSaver.primaryEditor = atom.workspace.getActiveTextEditor()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that logs the selection
    @subscriptions.add atom.commands.add 'atom-workspace',
      'selection-saver:add_selection_to_log': => @add_selection_to_log()

    # Register command that logs the selection
    @subscriptions.add atom.commands.add 'atom-workspace',
      'selection-saver:open_previous_file': => @open_previous_file()

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'selection-saver:toggle': => @toggle()

    # Now read the contents of the manifest and iterate over them
    # NOTE: readline does not pause the lines from the stream
    #console.log("Activating SelectionSaver and opening logPane: #{SelectionSaver.logFileURI}")
    #atom.workspace.open(SelectionSaver.logFileURI, split: 'down', searchAllPanes: true, activatePane: false)

    fs = require('fs')
    util = require('util')
    stream = require('stream')
    es = require('event-stream')
    SelectionSaver.manifestStream = fs.createReadStream(manifestPath).pipe(es.split()).pipe(es.mapSync((fileToOpen) ->
      # pause the readstream
      SelectionSaver.manifestStream.pause()

      # Open the file
      SelectionSaver.primaryFile = fileToOpen
      if fileToOpen == ''
        console.log 'Skipping line with no File'
        SelectionSaver.manifestStream.resume()
        return
      console.log 'File to Open:', fileToOpen
      atom.workspace.open(fileToOpen, split: 'up', searchAllPanes: true, activatePane: true)

      # Set/Update the primaryPane and primaryEditor to this new file
      SelectionSaver.primaryPane = atom.workspace.getActivePane()
      SelectionSaver.primaryEditor = atom.workspace.getActiveTextEditor()
      # console.log("primaryPane", SelectionSaver.primaryPane)     # DEBUG
      # console.log("primaryEditor", SelectionSaver.primaryEditor) # DEBUG


      # Check to see if we need to reopen the log
      openFilePaths = atom.workspace.getTextEditors().map((e) ->
        e.getPath()
      )
      if openFilePaths.indexOf(SelectionSaver.logFileURI) == -1
        # logPane is not open, so open it
        SelectionSaver.toggle()

      # resume the readstream from a callback
      return
    ).on('error', ->
      console.log "Error while reading manifest file: #{manifestPath}"
      return
    ).on('end', ->
      console.log "Read entire manifest file: #{manifestPath}"
      console.log "Reloading Window"
      atom.reload()
      #console.log "Deactivating the package"
      #SelectionSaver.deactivate()
      return
    ))


  open_previous_file: ->
      atom.workspace.open(SelectionSaver.previousFile, activatePane: true)
      SelectionSaver.previousFileIsOpen = 1


  deactivate: ->
    # Destroy any pane with the log file in it
    atom.workspace.getPanes().map((p) ->
      if p.itemForURI(SelectionSaver.logFileURI)
        p.destroy()
    )
    @subscriptions.dispose()
    console.log("SelectionSaver deactivated")


  add_selection_to_log: ->
    # console.log("logPane", SelectionSaver.logPane)              # DEBUG
    # console.log("logEditor", SelectionSaver.logEditor)          # DEBUG
    # console.log("primaryPane", SelectionSaver.primaryPane)      # DEBUG
    # console.log("primaryEditor", SelectionSaver.primaryEditor)  # DEBUG

    # Get the file, row num and selection
    selection = SelectionSaver.primaryEditor.getSelectedText()
    selectionRow = SelectionSaver.primaryEditor.getCursorBufferPosition().row+1 # row is 0 indexed
    # selectionFilePath = SelectionSaver.primaryEditor.getPath()
    selectionFilePath = SelectionSaver.primaryFile # use the exact line from the manifest
    selectionFilePath = SelectionSaver.previousFile if SelectionSaver.previousFileIsOpen?
    # console.log "#{selectionFilePath}|#{selectionRow}|#{selection}" # DEBUG

    SelectionSaver.logPane.activate()
    logBuffer = SelectionSaver.logEditor.getBuffer()
    logBuffer.append("#{selectionFilePath}|#{selectionRow}|#{selection}\n")
    SelectionSaver.logEditor.scrollToBottom()
    SelectionSaver.logEditor.save()

    SelectionSaver.primaryPane.activate()

  toggle: ->
    # Toggle enable or disable of package
    #if atom.packages.isPackageActive('selection-saver')
    #  SelectionSaver.deactivate()
    #else
    #  SelectionSaver.activate()

    # Get the list of open editors
    openFilePaths = atom.workspace.getTextEditors().map((e) ->
      e.getPath()
    )
    if openFilePaths.indexOf(SelectionSaver.logFileURI) == -1
      # logPane is not open, so open it
      console.log("Toggling logPane to OPEN")
      atom.workspace.open(SelectionSaver.logFileURI, split: 'down', searchAllPanes: true, activatePane: false)
      SelectionSaver.primaryPane.activate() # Put focus back on primary
      # Fiddling here with potentially resizing the pane as it is created
      #panes = document.getElementsByTagName("atom-pane")
      #panes.getElementsByClassName("
      #$('.pane.active').css('-webkit-flex').split ''
      #document.resizeBy(0, -200);

    else
      # logPane is open, so close it
      # SelectionSaver.logPane.destroy()
      console.log("Toggling logPane to CLOSED")
      atom.workspace.getPanes().map((p) ->
        if p.itemForURI(SelectionSaver.logFileURI)
          p.destroy()
      )
