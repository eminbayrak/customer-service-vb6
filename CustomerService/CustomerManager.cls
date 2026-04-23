VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 3  'UsesTransaction
END
Attribute VB_Name = "CustomerManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

' Database Connection String (retrieved from Registry/INI in real VB6)
Private Const CONN_STRING = "Provider=SQLOLEDB;Data Source=CUSTOMERS_DB;Initial Catalog=Customers;Integrated Security=SSPI;"

' --- Public Interface ---

' Returns customer details as an XML string (common in VB6 SOAP wrappers)
Public Function GetCustomer(ByVal CustomerId As String, ByVal SessionToken As String) As String
    On Error GoTo ErrorHandler
    
    Dim conn As New ADODB.Connection
    Dim rs As New ADODB.Recordset
    Dim xml As String
    
    ' Validate session
    If Not ValidateSession(SessionToken) Then
        Err.Raise 401, "CustomerManager", "Invalid session token"
    End If
    
    conn.Open CONN_STRING
    rs.Open "SELECT * FROM Customers WHERE CustomerId = '" & Replace(CustomerId, "'", "''") & "'", conn, adOpenStatic, adLockReadOnly
    
    If rs.EOF Then
        GetCustomer = BuildErrorXml("Customer not found")
        GoTo CleanUp
    End If
    
    ' Business Rule: Block access to "Deactivated" customers unless user is Admin
    If rs("Status") = "Deactivated" And Not IsAdmin(SessionToken) Then
        GetCustomer = BuildErrorXml("Customer account is deactivated. Contact administration.")
        GoTo CleanUp
    End If
    
    ' Business Rule: VIP customers require "Tier-1" support clearance
    If rs("Tier") = "VIP" And GetClearanceLevel(SessionToken) < 1 Then
        GetCustomer = BuildErrorXml("Insufficient clearance to view VIP customer details.")
        GoTo CleanUp
    End If
    
    xml = "<Customer>" & vbCrLf
    xml = xml & "  <CustomerId>" & rs("CustomerId") & "</CustomerId>" & vbCrLf
    xml = xml & "  <Name>" & rs("Name") & "</Name>" & vbCrLf
    xml = xml & "  <Email>" & rs("Email") & "</Email>" & vbCrLf
    xml = xml & "  <Tier>" & rs("Tier") & "</Tier>" & vbCrLf
    xml = xml & "  <Status>" & rs("Status") & "</Status>" & vbCrLf
    xml = xml & "  <CreditLimit>" & rs("CreditLimit") & "</CreditLimit>" & vbCrLf
    xml = xml & "</Customer>"
    
    GetCustomer = BuildSuccessXml(xml)

CleanUp:
    If rs.State = adStateOpen Then rs.Close
    If conn.State = adStateOpen Then conn.Close
    Exit Function

ErrorHandler:
    GetCustomer = BuildErrorXml(Err.Description)
    Resume CleanUp
End Function

Public Function UpdateProfile(ByVal CustomerId As String, ByVal Email As String, ByVal SessionToken As String) As String
    On Error GoTo ErrorHandler
    
    Dim conn As New ADODB.Connection
    
    ' Validate session
    If Not ValidateSession(SessionToken) Then
        Err.Raise 401, "CustomerManager", "Invalid session token"
    End If
    
    ' Business Rule: Email domains must be validated against a whitelist for Corporate accounts
    If InStr(1, Email, "@") = 0 Then
        UpdateProfile = BuildErrorXml("Invalid email format")
        Exit Function
    End If
    
    conn.Open CONN_STRING
    conn.Execute "UPDATE Customers SET Email = '" & Replace(Email, "'", "''") & "' WHERE CustomerId = '" & Replace(CustomerId, "'", "''") & "'"
    
    UpdateProfile = BuildSuccessXml("<Result>Profile updated successfully</Result>")
    
CleanUp:
    If conn.State = adStateOpen Then conn.Close
    Exit Function

ErrorHandler:
    UpdateProfile = BuildErrorXml(Err.Description)
    Resume CleanUp
End Function

' --- Private Helpers ---

Private Function ValidateSession(ByVal token As String) As Boolean
    ' In a real VB6 app, this might call another COM+ component or check a shared SessionStore
    ValidateSession = (Len(token) > 0)
End Function

Private Function IsAdmin(ByVal token As String) As Boolean
    ' Simulated check
    IsAdmin = (InStr(1, token, "admin") > 0)
End Function

Private Function GetClearanceLevel(ByVal token As String) As Integer
    ' Simulated clearance level check
    If InStr(1, token, "tier1") > 0 Then
        GetClearanceLevel = 1
    ElseIf InStr(1, token, "admin") > 0 Then
        GetClearanceLevel = 2
    Else
        GetClearanceLevel = 0
    End If
End Function

Private Function BuildSuccessXml(ByVal innerContent As String) As String
    BuildSuccessXml = "<?xml version=""1.0""?><CustomerManagerResult><Success>True</Success>" & innerContent & "</CustomerManagerResult>"
End Function

Private Function BuildErrorXml(ByVal errMsg As String) As String
    BuildErrorXml = "<?xml version=""1.0""?><CustomerManagerResult><Success>False</Success><ErrorMessage>" & errMsg & "</ErrorMessage></CustomerManagerResult>"
End Function
