<%
' CustomerManager.asp — SOAP endpoint
' Exposed via Microsoft SOAP Toolkit 3.0 (MSSOAP)
' IIS maps requests to this page; the SoapServer dispatches to CustomerManager.cls

Dim oSoapServer
Set oSoapServer = Server.CreateObject("MSSOAP.SoapServer")
Call oSoapServer.Init(Server.MapPath("CustomerManager.wsdl"), Server.MapPath("CustomerManager.wsml"))
Call oSoapServer.SoapInvoke(Request, Response, "")
Set oSoapServer = Nothing
%>
