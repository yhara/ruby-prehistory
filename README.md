# ruby-prehistory

[ruby/ruby](https://github.com/ruby/ruby) contains history of Ruby
development since 1998. This is the very first commit in ruby/ruby.

```
commit 392296c12de9d7f9be03a8205250ba0844cb9d38
Author: (no author) <(no author)@b2dd03c8-39d4-4d8f-98ff-823fe69b080e>
Date:   Fri Jan 16 12:13:05 1998 +0000

    New repository initialized by cvs2svn.

    git-svn-id: svn+ssh://ci.ruby-lang.org/ruby/trunk@1 b2dd03c8-39d4-4d8f-98ff-823fe69b080e
```

But actually this is not the birth of Ruby, as the word "New repository" indicates.
You can get the old archives here:

http://ftp.ruby-lang.org/pub/ruby/

This tool downloads and converts them into a git repository, so that you can
trace the diffs between very old ruby, 0.xx for example.

## Usage

```
$ mkdir old_rubies
$ ruby make.rb old_rubies
```

This will get the archives, create git repo, unpack each and add the content to the repo.

## License

MIT
