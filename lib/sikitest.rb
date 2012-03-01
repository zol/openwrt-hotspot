require 'siki-template'

attribute_template = <<END
<html>
  <body>
    <h1 href="foo" dummy="$title">
      this is the target element named "title"
      this element (or text) will replace
    </h1>
    <p dummy="$body">
      this is the target element named "body"
      this element (or text) will replace.
    </p>
  </body>
</html>
END

f = AttrString.new("foo", {"href" => "google.com"})

data = {                                               
  :title => f,
  :body => ["One", "Two", AttrString.new(nil, {"href" => "boogle.com"})]
} 

template = SikiTemplate::Template.new( attribute_template )
result = template.parse( data )
print result

#puts "#{f.to_s()}"
