#
# preferences.rb 
#
# dialog to set preferences for su2ds.rb
#
# written by Thomas Bleicher, tbleicher@gmail.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the
# Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA 02111-1307, USA, or go to
# http://www.gnu.org/copyleft/lesser.txt.

## defaults



def loadPreferences(interactive=0)
    ## check if config.rb exists in su2dslib
    configPath = File.expand_path('config.rb', File.dirname(__FILE__))
    if File.exists?(configPath)
        printf "++ found preferences file '#{configPath}'\n"
        begin
            load configPath ## this "runs" the file configPath points at, which consists of global vars being set
            printf "++ applied preferences from '#{configPath}'\n"
        rescue => e 
            printf "-- ERROR reading preferences file '#{configPath}'!\n"
            msg = "-- %s\n\n%s" % [$!.message,e.backtrace.join("\n")]
            printf msg
        end
    elsif interactive != 0
        begin
            f = File.new(configPath, 'w')
            f.write("#\n# config.rb\n#\n")
            f.close()
            pd = PreferencesDialog.new(configPath)
            pd.showDialog()
        rescue => e
            printf "ERROR creating preferences file '#{configPath}'!\n"
            printf "Preferences will not be saved.\n"
        end
    end
    
end


class PreferencesDialog

    def initialize(filepath='') ## filepath pretty much always going to be nil in normal usage

        @filepath = File.expand_path('config.rb', File.dirname(__FILE__))
        
        @loglevel   = 0                             ## level of report messages
        @triangulate = false                        ## export faces as triangles (should always work)
        @unit       = 0.0254                        ## use meters for Radiance scene
        @supportdir = '/Library/Application Support/Google Sketchup 7/Sketchup'  ## this is mainly used for material stuff
        @build_material_lib = false                 ## update/create material library in file system
       
        printf "\n=====\nPreferencesDialog('#{filepath}')\n=====\n"
        
        if filepath != ''
            filepath = File.expand_path(filepath, File.dirname(__FILE__))
            updateFromFile(filepath)
        end
    end
    
    ## runs config.rb, which assigns stored preference values to global variables,
    ## and then assigns global variable values to instance variables
    def updateFromFile(filepath) 
        if File.exists?(filepath)
            begin
                load filepath
                @filepath = filepath
                printf "settings updated from file '#{filepath}\n"
            rescue => e
                printf "ERROR reading preferences file '#{filepath}'!\n"
                msg = "%s\n\n%s" % [$!.message,e.backtrace.join("\n")]
                return
            end
        end
        ## now all values are in global vars
        @loglevel   = $LOGLEVEL
        @triangulate = $TRIANGULATE
        @unit       = $UNIT
        @supportdir = $SUPPORTDIR
        @build_material_lib = $BUILD_MATERIAL_LIB
        validate()
    end

    def validate
        ## check settings after loading from file
        if @supportdir != '' and not File.exists?(@supportdir)
            printf "$SUPPORTDIR does not exist => setting ignored ('#{@supportdir}')\n"
            @supportdir = ''
            $SUPPORTDIR = ''
        end
    end
    
    def showDialog
        updateFromFile(@filepath) ## updates settings from config.rb
        a = (-12..12).to_a
        a.collect! { |i| "%.1f" % i }
        utcs = 'nil|' + a.join("|")
        prompts = [   'log level',  'triangulate faces']
        values  = [     @loglevel,      @triangulate.to_s]
        choices = [     '0|1|2|3',     'true|false']
        prompts += [  'unit', 'supportdir',         'update library']
        values  += [@unit,  @supportdir, @build_material_lib.to_s]
        choices += [        '',           '',             'true|false']
        
        dlg = UI.inputbox(prompts, values, choices, 'preferences')
        if not dlg
            printf "preferences dialog.rb canceled\n"
            return 
        else
            evaluateDialog(dlg) 
            applySettings()
            writeValues
        end
    end
    
    def evaluateDialog(dlg)
        @loglevel    = dlg[0].to_i
        @triangulate = truefalse(dlg[1])
        begin
            @unit = dlg[2].to_f
        rescue
            printf "unit setting not a number('#{dlg[2]}') => ignored\n"
        end 
        @supportdir = dlg[3]
        @build_material_lib = dlg[4]
        validate()
    end    
    
    def truefalse(s)
        if s == "true"
            return true
        else
            return false
        end
    end
    
    def showFile
        begin
            f = File.new(@filepath, 'r')
            printf f.read()
            printf "\n\n"
            f.close()
        rescue => e
            printf "\n-- ERROR reading preferences file '#{@filepath}'!\n"
        end 
    end 
    
    def showValues
        updateFromFile(@filepath)
        text = getSettingsText()
        printf "settings in file:\n"
        printf "#{text}\n"
    end

    def writeValues
        values = getSettingsText()
        text = ['#',
                '# config.rb',
                '#',
                '# This file is generated by a script.',
                "# Do not change unless you know what you're doing!",
                '',
                values, ''].join("\n")
        begin
            f = File.new(@filepath, 'w')
            f.write(text)
            f.close()
            printf "=> wrote file '#{@filepath}'\n"
        rescue => e
            printf "ERROR creating preferences file '#{@filepath}'!\n"
            printf "Preferences will not be saved.\n"
        end
        showValues()
    end

    def applySettings
        $LOGLEVEL   = @loglevel
        $TRIANGULATE = @triangulate
        $UNIT       = @unit
        $SUPPORTDIR = @supportdir
        $BUILD_MATERIAL_LIB = @build_material_lib
    end
    
    def getSettingsText
        l= ["$LOGLEVEL              = #{$LOGLEVEL}",
            "$UNIT                  = %.4f" % $UNIT,
            "$SUPPORTDIR            = '#{$SUPPORTDIR}'",
            "$TRIANGULATE           = #{$TRIANGULATE}",
            "$BUILD_MATERIAL_LIB    = #{$BUILD_MATERIAL_LIB}",
            "$ZOFFSET               = nil"]
        return l.join("\n")
    end
end

def preferencesTest
    begin
        ld = PreferencesDialog.new()
        ld.showDialog()
    rescue => e 
        msg = "%s\n\n%s" % [$!.message,e.backtrace.join("\n")]
        UI.messagebox msg            
    end 
end



