library Woocommerce;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  //ShareMem,
  System.SysUtils,
  System.Classes,
  REST.Types, REST.Client,
  Generics.Collections,
  Data.Bind.Components, Data.Bind.ObjectScope, REST.Authenticator.OAuth,
  REST.Response.Adapter, Rest.Json, REST.Authenticator.Basic;

{$R *.res}
var
RESTRequest : TRESTRequest;
RESTClient: TRESTClient;
RESTResponse: TRESTResponse;
WooAuth: TOAuth1Authenticator;


procedure CreateRest;stdcall;
begin
  RESTRequest := TRESTRequest.Create(nil);
  RESTClient := TRESTClient.Create(nil);
  RESTResponse := TRESTResponse.Create(nil);
  WooAuth := TOAuth1Authenticator.Create(nil);
end;

procedure FreeRest;stdcall;
begin
  FreeAndNil(RESTRequest);
  FreeAndNil(RESTClient);
  FreeAndNil(RESTResponse);
  FreeAndNil(WooAuth);
end;

procedure Ligacoes(Url:string; Verbo:TRESTRequestMethod);stdcall;
begin
  //Liga��es
  RESTClient.Authenticator := WooAuth;
  RESTClient.BaseURL := Url;
  RESTRequest.Method := Verbo;
  RESTRequest.Response := RESTResponse;
  RESTRequest.Client := RESTClient;
end;

procedure Assinatura(wCK, wCS: string);stdcall;
var
  oauth_signature: String;
begin
  //Dados para assinatura
  WooAuth.ConsumerKey := wCK;
  WooAuth.ConsumerSecret := wCS;
  RESTRequest.AddParameter('oauth_consumer_key', wCK);
  RESTRequest.AddParameter('oauth_signature_method', WooAuth.SignatureMethod);
  RESTRequest.AddParameter('oauth_nonce', WooAuth.nonce);
  RESTRequest.AddParameter('oauth_timestamp', WooAuth.timeStamp.DeQuotedString);
  RESTRequest.AddParameter('oauth_version', WooAuth.Version);
  oauth_signature := WooAuth.SigningClass.BuildSignature(RESTRequest, WooAuth);
  RESTRequest.AddParameter('oauth_signature', oauth_signature);
end;

function OlaMundo(Usuario:string):WideString;stdcall;
begin
  Result := 'Ol�! seja bem vindo, '+ Usuario;
end;

function GetCategoria(Url, CK, CS, ID:string):WideString;stdcall;
begin
  try
    Result := '';

    CreateRest;
    Ligacoes(Url, rmGET);

    if Trim(ID) <> EmptyStr then
      RESTRequest.Resource := '/products/categories'+'/'+ID
    else
      RESTRequest.Resource := '/products/categories';

    Assinatura(CK, CS);
    RESTRequest.Execute;

    if assigned(RESTResponse.JSONValue) then
      Result := TJson.Format(RESTResponse.JSONValue)
    else
      Result := RESTResponse.Content;
  finally
    FreeRest;
  end;
end;

function PostCategoria(Url, CK, CS, name, slug, parent, description:string):wideString; stdcall;
var sParent, jSON:string;
begin
  try
    Result := '';

    CreateRest;
    Ligacoes(Url, rmPOST);
    RESTRequest.Resource := '/products/categories';

    Assinatura(CK, CS);

    if Trim(parent) <> EmptyStr then
      sParent := parent
    else
      sParent := '0';

    jSON :=
        '{'+
          '"name": "' + name +'",'+
          '"slug": "' + slug +'",'+
          '"parent": "' + sParent + '", '+
          '"description": "' + description + '" '+
        '}';

    RESTRequest.AddBody(jSON, ContentTypeFromString('application/json'));

    RESTRequest.Execute;

    if assigned(RESTResponse.JSONValue) then
      Result := TJson.Format(RESTResponse.JSONValue)
    else
      Result := RESTResponse.Content;
  finally
    FreeRest;
  end;
end;

function PutCategoria(Url, CK, CS, ID, name, slug, parent, description:string):wideString; stdcall;
var jSON:string;
begin
  try
    Result := '';

    CreateRest;
    Ligacoes(Url, rmPATCH);
    RESTRequest.Resource := '/products/categories'+'/'+ID;
    Assinatura(CK, CS);

    jSON :=
        '{'+
          '"name": "' + name + '",'+
          '"slug": "' + slug + '"'+
        '}';
    RESTRequest.AddBody(jSON, ContentTypeFromString('application/json'));

    RESTRequest.Execute;

    if assigned(RESTResponse.JSONValue) then
      Result := TJson.Format(RESTResponse.JSONValue)
    else
      Result := RESTResponse.Content;
  finally
    FreeRest;
  end;
end;

function DelCategoria(Url, CK, CS, ID:string):wideString; stdcall;
var jSON:string;
begin
  try
    Result := '';

    CreateRest;
    Ligacoes(Url, rmDELETE);
    RESTRequest.Resource := '/products/categories'+'/'+ID;
    Assinatura(CK, CS);
    RESTRequest.Execute;

    if assigned(RESTResponse.JSONValue) then
      Result := TJson.Format(RESTResponse.JSONValue)
    else
      Result := RESTResponse.Content;
  finally
    FreeRest;
  end;
end;

function GetProduto(Url, CK, CS, ID:string):WideString;
begin
  try
    Result := '';

    CreateRest;
    Ligacoes(Url, rmGET);

    if Trim(ID) <> EmptyStr then
      RESTRequest.Resource := '/products'+'/'+ID
    else
      RESTRequest.Resource := '/products';

    Assinatura(CK, CS);
    RESTRequest.Execute;

    if assigned(RESTResponse.JSONValue) then
      Result := TJson.Format(RESTResponse.JSONValue)
    else
      Result := RESTResponse.Content;
  finally
    FreeRest;
  end;
end;


function PostProduto(Url, CK, CS, name, slug, description,
short_description, sku, price, regular_price, sale_price,
_length, _width, _height:string; categories: TList<string>):wideString;

var jSON, cat:string;
  I: Integer;
begin
  try
    try
      Result := '';

      CreateRest;
      Ligacoes(Url, rmPOST);
      RESTRequest.Resource := '/products';
      Assinatura(CK, CS);

      if categories.Count = 0 then
        cat := '{}'
      else if categories.Count = 1 then
      begin
        cat := '{"id": ' + categories[0] + '}';
      end
      else if categories.Count > 1 then
      begin
        for I := 0 to categories.Count do
          cat := cat + '{"id": ' + categories[I] + '},';

        Delete(cat,length(cat),1);
      end;

      jSON :=
          '{'+
            '"name": "' + name + '",'+
            '"slug": "' + slug +'",'+
            '"type": "simple",'+
            '"description": "'+ description +'",'+
            '"short_description": "'+ short_description +'",'+
            '"sku": "'+ sku +'",'+
            '"price": "'+ price +'",'+
            '"regular_price": "'+ regular_price +'",'+
            '"sale_price": "'+ sale_price +'",'+
            '"dimensions":'+
                '{'+
                  '"length": "' + _length + '",'+
                  '"width": "' + _width + '",'+
                  '"height": "' + _height + '"'+
                '},'
                +
            '"categories":'+
                '['+
                     cat
                   +
                ']'+
          '}';

      RESTRequest.AddBody(jSON, ContentTypeFromString('application/json'));

      RESTRequest.Execute;

      if assigned(RESTResponse.JSONValue) then
        Result := TJson.Format(RESTResponse.JSONValue)
      else
        Result := RESTResponse.Content;
    except on E: Exception do
      Result := ('Erro Tentar Postar o Produto - ' + chr(13)+E.Message);
    end;
  finally
    FreeRest;
  end;
end;

function PutProduto(Url, CK, CS, name, slug, description,
short_description, sku, price, regular_price, sale_price,
_length, _width, _height, ID:string):wideString;

var jSON:string;
  I: Integer;
begin
  try
    Result := '';

    CreateRest;
    Ligacoes(Url, rmPATCH);
    RESTRequest.Resource := '/products'+'/'+ID;
    Assinatura(CK, CS);

    jSON :=
        '{'+
          '"name": "' + name + '",'+
          '"slug": "' + slug +'",'+
          '"type": "simple",'+
          '"description": "'+ description +'",'+
          '"short_description": "'+ short_description +'",'+
          '"sku": "'+ sku +'",'+
          '"price": "'+ price +'",'+
          '"regular_price": "'+ regular_price +'",'+
          '"sale_price": "'+ sale_price +'",'+
          '"dimensions":'+
              '{'+
                '"length": "' + _length + '",'+
                '"width": "' + _width + '",'+
                '"height": "' + _height + '"'+
              '}'+
        '}';

    RESTRequest.AddBody(jSON, ContentTypeFromString('application/json'));

    RESTRequest.Execute;

    if assigned(RESTResponse.JSONValue) then
      Result := TJson.Format(RESTResponse.JSONValue)
    else
      Result := RESTResponse.Content;
  finally
    FreeRest;
  end;
end;

function DelProduto(Url, CK, CS, ID:string):wideString; stdcall;
var jSON:string;
begin
  try
    Result := '';

    CreateRest;
    Ligacoes(Url, rmDELETE);
    RESTRequest.Resource := '/products'+'/'+ID;
    Assinatura(CK, CS);
    RESTRequest.Execute;

    if assigned(RESTResponse.JSONValue) then
      Result := TJson.Format(RESTResponse.JSONValue)
    else
      Result := RESTResponse.Content;
  finally
    FreeRest;
  end;
end;


exports

OlaMundo,
GetCategoria,
PostCategoria,
PutCategoria,
DelCategoria,
GetProduto,
PostProduto,
PutProduto,
DelProduto;

begin
end.
