*** Settings ***
Documentation   Testy funkcjonalności odłączania UE od sieci w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

*** Variables ***
${BASE_URL}             http://localhost:8000

*** Keywords ***
Setup API Session
    Create Session    epc    ${BASE_URL}
    POST On Session    epc    /reset    expected_status=any

Attach UE
    [Arguments]    ${ue_id}
    &{body}=        Create Dictionary    ue_id=${ue_id}
    ${response}=    POST On Session    epc    /ues    json=${body}    expected_status=any
    RETURN    ${response}

Detach UE
    [Arguments]    ${ue_id}
    ${response}=    DELETE On Session    epc    /ues/${ue_id}    expected_status=any
    RETURN    ${response}

Get UE State
    [Arguments]    ${ue_id}
    ${response}=    GET On Session    epc    /ues/${ue_id}    expected_status=any
    RETURN    ${response}

Status Code Should Be
    [Arguments]    ${response}    ${expected}
    Should Be Equal As Integers    ${response.status_code}    ${expected}

Status Code Should Be Error
    [Arguments]    ${response}
    Should Be True    ${response.status_code} >= 400

*** Test Cases ***
TC01 Odlaczenie Podlaczonego UE Od Sieci
    [Documentation]    Podłączone UE może zostać poprawnie odłączone od sieci.
    [Setup]    Setup API Session
    ${attach}=    Attach UE    10
    Status Code Should Be    ${attach}    200
    ${detach}=    Detach UE    10
    Status Code Should Be    ${detach}    200

TC02 Po Odlaczeniu UE Nie Ma Go W Systemie
    [Documentation]    Po odłączeniu UE zapytanie GET na ten UE zwraca błąd.
    [Setup]    Setup API Session
    Attach UE    10
    Detach UE    10
    ${state}=    Get UE State    10
    Status Code Should Be Error    ${state}

TC03 Odlaczenie Niepodlaczonego UE Zwraca Blad
    [Documentation]    Próba odłączenia UE które nie jest podłączone zwraca błąd.
    [Setup]    Setup API Session
    ${resp}=    Detach UE    99
    Status Code Should Be Error    ${resp}

TC04 Podwojne Odlaczenie Tego Samego UE Zwraca Blad
    [Documentation]    Drugie odłączenie tego samego UE powinno zwrócić błąd.
    [Setup]    Setup API Session
    Attach UE    10
    Detach UE    10
    ${second}=    Detach UE    10
    Status Code Should Be Error    ${second}

TC05 Ponowne Podlaczenie Po Odlaczeniu Jest Mozliwe
    [Documentation]    UE odłączone od sieci może zostać ponownie podłączone.
    [Setup]    Setup API Session
    Attach UE    10
    Detach UE    10
    ${reattach}=    Attach UE    10
    Status Code Should Be    ${reattach}    200

TC06 Odlaczenie Jednego UE Nie Wplywa Na Drugie UE
    [Documentation]    Odłączenie jednego UE nie powoduje odłączenia innych UE w systemie.
    [Setup]    Setup API Session
    Attach UE    10
    Attach UE    20
    Detach UE    10
    ${state}=    Get UE State    20
    Status Code Should Be    ${state}    200
