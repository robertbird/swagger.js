window.context = window.describe
window.xcontext = window.xdescribe

describe 'Api', ->
  
  describe 'constructor', ->

    describe 'defaults', ->
    
      beforeEach ->
        window.wordnik = new Api()
        waitsFor ->
          wordnik
      
      it "sets the default discoveryUrl to wordnik's production API", ->
        runs ->
          expect(wordnik.discoveryUrl).toBe("http://api.wordnik.com/v4/resources.json")

      it "disables the debugger by default", ->
        runs ->
          expect(wordnik.debug).toBe(false)
      
      # it "builds right away if a callback was passed to the initializer", ->
      #   runs ->
      #     expect(true).toBe(false)
      
    describe 'customization', ->

      beforeEach ->
        window.unicornApi = new Api
          discoveryUrl: "http://unicorns.com"
          debug: true
          apiKey: 'stardust'

        waitsFor ->
          unicornApi
    
      it "allows discoveryUrl to be set", ->
        runs ->
          expect(unicornApi.discoveryUrl).toBe("http://unicorns.com")
    
      it "allows debugging to be enabled", ->
        runs ->
          expect(unicornApi.debug).toBe(true)
      
      it "converts apiKey to api_key", ->
        runs ->
          expect(unicornApi.api_key).toBe('stardust')
          
  describe 'build', ->
    
      beforeEach ->
        window.wordnik = new Api
        wordnik.build()
        waitsFor ->
          wordnik.isReady()
    
      it "fetches a list of resources", ->
        runs ->
          expect(wordnik.resources.length).toBeGreaterThan(0)
          
      it "sets basePath", ->
        runs ->
          expect(wordnik.basePath).toBe("http://api.wordnik.com/v4")
          
      it "creates named references to its resources", ->
        runs ->
          expect(wordnik.words).toBeDefined()
          
describe 'Resource', ->
  
  beforeEach ->
    window.wordnik = new Api()
    wordnik.build()
    waitsFor ->
      wordnik.isReady()
        
  it "has a url()", ->
    runs ->
      resource = wordnik.resources[0]
      expect(resource.url()).toMatch(/\.json$/)
      
  it "has a name() method which is inferred from its path", ->
    runs ->
      resource = new Resource("/word.{format}", "an imaginary resource", wordnik)
      expect(resource.name()).toEqual('word')
        
  it "creates named references to its operations", ->
    runs ->
      resource = wordnik.word
      expect(resource.getDefinitions).toBeDefined()

describe 'Operation', ->
  
  beforeEach ->
    window.wordnik = new Api()
    wordnik.api_key = 'b39ee8d5f05d0f566a0080b4c310ceddf5dc5f7606a616f53'
    wordnik.build()
    waitsFor ->
      wordnik.isReady()

  describe "urlify", ->

    beforeEach ->
      window.operation = wordnik.word.getDefinitions
      operation.path = "/my.{format}/{foo}/kaboo"
      operation.parameters = [{paramType: 'path', name: 'foo'}]
      window.args = {foo: 'pee'}

    it "automatically converts {format} to json", ->
      runs ->
        expect(operation.urlify(args)).toMatch(/my\.json/) 

    it "injects path arguments into the path", ->
      runs ->
        expect(operation.urlify(args)).toMatch(/\/pee\/kaboo/)

    it "throws an exception if path has unmatched arguments", ->
      runs ->
        args = {}
        expect(-> operation.urlify(args) ).toThrow("foo is a required path param.")

  describe "do", ->

    beforeEach ->
      window.args =
        word: 'flagrant'
        limit: 3
      window.response = null

    it "gets back an array of definitions", ->
      wordnik.word.getDefinitions.do args, (response) ->
        window.response = response
      
      waitsFor ->
        response?

      runs ->
        expect(response.length).toBeGreaterThan(0)
        expect(response[0].word).toBeDefined()
        expect(response[0].text).toBeDefined()
        expect(response[0].partOfSpeech).toBeDefined()
          
    it "pulls request headers out of the args object", ->
      args.headers = 
        'head-cheese': 'certainly'
      window.request = wordnik.word.getDefinitions.do args, (response) ->
        window.response = response
      
      waitsFor ->
        response?

      runs ->
        expect(request.headers).toBeDefined()
        expect(request.headers['head-cheese']).toBeDefined()
    
    it "pulls request body out of the args object", ->
      args.body = 
        'name': 'haute couture'
        'pronunciation': 'hottie cooter-otty'
      window.request = wordnik.word.getDefinitions.do args, (response) ->
        window.response = response
      
      waitsFor ->
        response?
      
      runs ->
        expect(request.body).toBeDefined()
        expect(request.body.name).toMatch(/haute/)
        expect(request.body.pronunciation).toMatch(/cooter/)
                        
describe 'Request', ->
  
  beforeEach ->
    window.wordnik2 = new Api()
    wordnik2.api_key = 'magic'
    wordnik2.build()
    waitsFor ->
      wordnik2.isReady()

  describe "constructor", ->

    beforeEach ->
      headers =
        'mock': 'true' # Request won't run if mock header is present
      body = null
      callback = ->
        'mock callback'
      operation = wordnik2.word.getExamples
      window.request = new Request("GET", "http://google.com", headers, body, callback, operation)

    it "sticks the API key into the headers, if present in the parent Api configuration", ->
      runs ->
        expect(request.headers.api_key).toMatch(/magic/)

  it "exposes an asCurl() method", ->
    curl = request.asCurl()
    expect(curl).toMatch(/curl --header \"mock: true\" --header \"api_key: magic\"/)