#! ruby
#

require 'nkf'

# �X�e�b�v���s���ǂ���
if ARGV.empty?
  def k(a)
    #do nothing
  end
else
  def k(msg)
    # �m�F�p�Ɉꎞ��~
    $stderr.print "#{msg} (P)"
    $stdin.gets().strip.empty? or exit
  end
end

def extract_files(leaf)
  k "enter in tree of #{leaf}"
  `git ls-tree #{leaf}`.each do |item|
    k "Target leaf: #{item}"
    mode, otype, hash, name = item.split(' ',4)
    case NKF.guess(name)
    when NKF::SJIS
      k "encoding of name will be SJIS"
    when NKF::UTF8
      k "encoding of name will be UTF-8"
    when NKF::ASCII
      k "encoding of name will be ASCII"
    else
      k "Other encoding"
    end
    #k "encoding of sname will be #{NKF.guess(sname)}."
    sname = NKF.nkf('-s', name)
    uname = NKF.nkf('-w', name)
    #k "actual name: #{uname}"
    case otype
    when 'blob'
      k "blob"
      system("git cat-file blob #{hash} > \"#{sname}\"") or raise
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
      Dir.mkdir(uname)
      k "Entering into #{uname}"
      Dir.chdir(uname)
      extract_files(hash)
      k "Leaving from #{uname}"
      Dir.chdir('..')
    else
      raise "Unknown object type"
    end
  end
end


# �ŌẪR�~�b�g��sha1���擾����D
commits = `git log --format=format:%H --reverse`.split
oldest_sha1 = commits[0]

k "# of commits : #{commits.size}, oldest:#{oldest_sha1} "

# �ŌẪR�~�b�g�ɑ΂���rebase��������D
# ���C���ׂẴR�~�b�g�ŏC������l�ɂ���D
#cmd = %Q!GIT_EDITOR='ruby -ibak -e "ARGF.each{|x| puts x.sub(/pick/,%q(edit))}"' git rebase -i #{oldest_sha1}!
ENV['GIT_EDITOR'] = %Q!ruby -ibak -e "ARGF.each{|x| puts x.sub(/pick/,'edit')}"!
k "ENV['GIT_EDITOR'] : #{ENV['GIT_EDITOR']} "
r = `bash echo $GIT_EDITOR | cat`
k "env GIT_EDITOR : #{r}"

cmd = "git rebase -i #{oldest_sha1}"
k "Rebase Command is \n#{cmd}\nIs it OK? "

#res = `#{cmd} | tee error.log`
#if $?.exitstatus != 0
#  raise "Error in starting rebase. #{res}"
#end
system(cmd)


k 'rebased to oldest.'


begin
  k "Create save dir if it does not exist"
  Dir.mkdir("../save") unless File.directory?("../save")

  commits.each_with_index do |commit,i|
    k "Starting commit# #{i}: #{commit}"


    # �܂��t�@�C�����̑����������ǂ��Ă��܂��D
    store = "../save/#{i}-#{commit}"

    k "Create destination: #{store} "
    Dir.mkdir(store) unless File.directory?(store)

    k "Moving existing files into #{store}"
    system("mv * #{store}/") or raise

    k "All files moved. (Is it OK?) "

    k "Reset all changes."
    # ���݂̕ύX�_�����Z�b�g
    system("git reset")
    k "reset."

    k "Start file extraction for HEAD"
    #���݂̃c���[�I�u�W�F�N�g���擾���C���[�v
    extract_files 'HEAD'

    k "adding all files "
    # ���ׂĂ�ǉ�
    system("git add --all")

    k "Modify Commits"
    #�R�~�b�g���C��
    system("git commit --amend")

    k "Continue rebasing"
    #���x�[�X�𑱍s
    system("git rebase --continue")
  end
rescue
  $stderr.puts "Rebase failed. Please run following commant to recover it\n  git rebase --abort"
  raise
end

k "Is rebase finished?"

