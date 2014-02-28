#! ruby
#

require 'nkf'

def mkdir(d)
  Dir.mkdir(d) unless File.directory?(d)
end

def k(a)
  #do nothing
  puts a
end

def extract_files(leaf, dir='.')
  k "enter in tree of #{leaf}"
  `git ls-tree #{leaf}`.each do |item|
    item.chomp!
    k "Target leaf: #{item}"
    mode, otype, hash, name = item.split(' ',4)
    sname = NKF.nkf('-s', name)
    uname = NKF.nkf('-w', name)
    case NKF.guess(name)
    when NKF::SJIS
      k "encoding of name will be SJIS"
    when NKF::UTF8
      k "encoding of name will be UTF-8"
      k "actual name: #{sname}"
    when NKF::ASCII
      k "encoding of name will be ASCII"
    else
      k "Other encoding"
    end
    case otype
    when 'blob'
      k "blob"
      system("git cat-file blob #{hash} > \"#{dir}/#{sname}\"") or raise
      k "extracted.  Changing mode"
      case mode
      when /644/
        #File.chmod(644, uname)
        k "No need to chenge mode (regular file)."
      when /755/
        #File.chmod(755, uname)
        system "chmod a+x #{sname}"
        k "File mode chenged to 755 (executable)."
      else
        raise
      end
    when 'tree'
      k "tree. Create Directory: #{sname}"
      sdir = dir + "/" + uname
      mkdir(sdir)
      extract_files(hash,sdir)
    else
      raise "Unknown object type"
    end
  end
end

out = '../save-extract'
mkdir out
puts `mv -r * #{out}/`

if ARGV.empty?
  extract_files('HEAD')
else
  extract_files ARGV.shift
end

exit

