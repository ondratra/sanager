import sublime
import sublime_plugin

brushCharacter = "/"
preSize = 20
postSize = 60
textOffset = 1

class ClassRegionCommentCommand(sublime_plugin.TextCommand):

    def run(self, edit):
        for region in self.view.sel():
            line = self.view.line(region);
            self.processLine(edit, line)

    def processLine(self, edit, line):
        originalLineContent = self.view.substr(line) # the text within the 'Region'
        lineContent = originalLineContent.strip(" " + brushCharacter);
        leadingSpaces = len(originalLineContent) - len(originalLineContent.lstrip())


        if (len (lineContent) and postSize > len(lineContent)):
            lineContent = " " * leadingSpaces + brushCharacter * (preSize - textOffset) + " " * textOffset + lineContent + " " * textOffset + brushCharacter * (postSize - len(lineContent) - textOffset - leadingSpaces)

            #print("asdf", postSize, len(lineContent), lineContent)
            self.view.replace(edit, line, lineContent)
