require "sinatra"

class App < Sinatra::Application
  get '/' do
    # ERROR: (pub/sub) cluster message size error. Message ignored.
    'index'
  end

  get '/slim' do
    # NoMethodError: undefined method `call' for ...
    slim 'index'
  end
end

::Iodine.subscribe(channel: :internal) {|_, _| 'nothing' }

class MySocket
  def on_message(data)
    ::Iodine.publish(channel: :internal, message: data)
  end
end

module MyRack
  def self.call(env)
    unless env['upgrade.websocket?']
      return [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
    end

    env['upgrade.websocket'] = MySocket

    [0, {}, []]
  end
end

app = Rack::Builder.new do
  map '/' do
    run App
  end
  map '/cable' do
    run MyRack
  end
end

run app

## Test for ERROR: (pub/sub) cluster message size error. Message ignored.
## Also works for NoMethodError: undefined method `call' for ...

# ws = new WebSocket("ws://localhost:3000/cable");
# ws.onopen = function(e) {
#     console.log("opened");
#     ws.send(JSON.stringify({"command":"subscribe","identifier":"{\"channel\":\"chat\",\"id\":\"hui\"}"}));
#     ws.send(JSON.stringify({command: "message", identifier: "{\"channel\":\"chat\",\"id\":\"hui\"}", data: "{\"message\":\"asht\",\"action\":\"speak\"}"}));
# };

## Simpiler test for NoMethodError: undefined method `call' for ...

# ws = new WebSocket("ws://localhost:3000/cable");
# ws.onopen = function(e) {
#     ws.send("message");
# };
