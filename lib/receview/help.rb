# -*- encoding: utf-8 -*-

class ReceViewHelp
  def ReceViewHelp::All_Help
    help = <<-EOF
    command: 
      -v | --version            Version information
      -c | --check              CSV Schema Check
      -m | --mount-check        Device Mount Check
           --clear-logfile      Purge LogFile
      -o | --open-dialog        OpenDialog StartUp (Not Run ARGV RECEFILE)
           --safe-printer       printer is safe initialized
           --set-printer        Set Defalut Printer name
           --other-csv          executes other CSV file modes.
           --non-other-csv      Dont executes other CSV file modes.
           --file-pattern       FilePattern with executes other CSV file modes.
           --sickname-complete  high-speed starting about reading in a file complement. 
                                for high spec machine.
           --enable-lock        runing Process check lockfile. (1way)

           --default-reander    Preview widget and output PDF embed image rendering
                                The reander of background and document is Setup.
                                  'PDF' or 'PNG' or 'CAIRO'.
                                  default:'PDF' For Linux.
                                  default:'PNG' For Windows.

                                The priority of an option
                                  default-reander > (background-reander || document_reander)

           --background-reander Preview widget rendering BaseData 'PDF' or 'PNG' or 'CAIRO'.
                                  default:'PDF' For Linux.
                                  default:'PNG' For Windows.

           --document-reander   output PDF embed image 'PDF' or 'PNG' or 'CAIRO'.
                                  default:'PDF' For Linux.
                                  default:'PNG' For Windows.

      ex: $jma-receview
      ex: $jma-receview /var/tmp/RECEIPTC.UKE
      ex: $jma-receview /var/tmp/RECEIPTC.HEN
      ex: $jma-receview /var/tmp/RECEIPTC.ISO
      ex: $jma-receview -v
      ex: $jma-receview -c /var/tmp/RECEIPTC.UKE
      ex: $jma-receview --check /var/tmp/RECEIPTC.UKE
      ex: $jma-receview -o
      ex: $jma-receview --open-dialog
      ex: $jma-receview -m
      ex: $jma-receview --mount-check
      ex: $jma-receview --clear-logfile
      ex: $jma-receview --safe-printer
      ex: $jma-receview --set-printer printer_name
      ex: $jma-receview --set-printer pdf
      ex: $jma-receview --set-printer pdf /var/tmp/RECEIPTC.UKE
      ex: $jma-receview --non-other-csv
      ex: $jma-receview --other-csv /cdrom/other.csv
      ex: $jma-receview --other-csv --file-pattern 99999999.csv /cdrom/other.csv
      ex: $jma-receview --other-csv --file-pattern test.uke /tmp/other.iso
      ex: $jma-receview --default-reander PNG
      ex: $jma-receview --default-reander PDF
      ex: $jma-receview --background-reander PNG
      ex: $jma-receview --background-reander PDF
      ex: $jma-receview --background-reander CAIRO
      ex: $jma-receview --document-reander PNG
      ex: $jma-receview --document-reander PDF
      ex: $jma-receview --background-reander PNG --document-reander PDF
      ex: $jma-receview --sickname-complete
      ex: $jma-receview --enable-lock
      ex: $jma-receview --background-reander PNG --sickname-complete

    Hint:
      Please specify the RECEDEN file for the last argument.

    debug:
      ex: $ruby -d -w jma-receview
      ex: jma/receview/dbslib.rb $DEBUG=true
          Please rewrite the status of a in 'true'.
    EOF
    help.gsub(/^ {4}/, "")
  end

  def ReceViewHelp::Other_CSV_Help
    help = <<-EOF
    command: 
      -v | --version        Version information
      -m | --mount-check    Device Mount Check
           --file-pattern   FilePattern with executes other CSV file modes.

      ex: $jma-receview-other
      ex: $jma-receview-other /var/tmp/1234567.UKE
      ex: $jma-receview-other /var/tmp/1234567.ISO
      ex: $jma-receview-other /var/tmp/42403_9912345678.CSV
      ex: $jma-receview -v
      ex: $jma-receview -m
      ex: $jma-receview --mount-check
      ex: $jma-receview /cdrom/other.csv
      ex: $jma-receview --file-pattern 99999999.csv /cdrom/other.csv
      ex: $jma-receview --file-pattern 9912345678.CSV /cdrom/42403_9912345678.CSV
      ex: $jma-receview --file-pattern 9912345678.csv /tmp/other.iso

    Hint:
      Please specify the RECEDEN file for the last argument.

    debug:
      ex: $ruby -d -w jma-receview-other
    EOF
    help.gsub(/^ {4}/, "")
  end

  def ReceViewHelp::Schema_Check
    print "Schema Test\n"
  end

  def ReceViewHelp::Mount_Test
    print "Disk Mount Test\n"
    yield
    print "done.\n"
  end

  def ReceViewHelp::Log_Chear(time=8)
    print "ReceView LogFile. ALL Clear.\n"
    print "wait for #{time.to_s} seconds. ([Ctrl+c] is pushed when stopping)\n"
    sleep time
    yield
    print "done.\n"
  end
end

if __FILE__ == $0
  puts ReceViewHelp.All_Help
end
