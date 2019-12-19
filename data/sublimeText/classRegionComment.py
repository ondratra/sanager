import sublime
import sublime_plugin
import os

brushCharacter = "/"
brushCharacterCss = "*"
preSize = 20
postSize = 60
textOffset = 1

class ClassRegionCommentCommand(sublime_plugin.TextCommand):

    def run(self, edit):
        extension = os.path.splitext(self.view.file_name())[1]

        for region in self.view.sel():
            line = self.view.line(region);
            if extension == ".css":
                self.processLineCss(edit, line)
            else:
                self.processLine(edit, line)

    def processLine(self, edit, line):
        originalLineContent = self.view.substr(line) # the text within the 'Region'
        lineContent = originalLineContent.strip(" " + brushCharacter);
        leadingSpaces = len(originalLineContent) - len(originalLineContent.lstrip())


        if (len(lineContent) and postSize > len(lineContent)):
            lineContent = " " * leadingSpaces + brushCharacter * (preSize - textOffset) + " " * textOffset + lineContent + " " * textOffset + brushCharacter * (postSize - len(lineContent) - textOffset - leadingSpaces)

            self.view.replace(edit, line, lineContent)

    def processLineCss(self, edit, line):
        originalLineContent = self.view.substr(line) # the text within the 'Region'
        lineContent = originalLineContent.strip(" *" + brushCharacter);
        leadingSpaces = len(originalLineContent) - len(originalLineContent.lstrip())

        if (len(lineContent) and postSize > len(lineContent)):
            lineContent = " " * leadingSpaces + brushCharacter + brushCharacterCss * (preSize - textOffset - 1) + " " * textOffset + lineContent + " " * textOffset + brushCharacterCss * (postSize - len(lineContent) - textOffset - leadingSpaces - 1) + brushCharacter

            self.view.replace(edit, line, lineContent)
