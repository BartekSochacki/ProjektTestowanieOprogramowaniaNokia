*** Settings ***
Documentation   Testy funkcjonalności sprawdzania statystyk transferu danych w symulatorze EPC.
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

Start Traffic
    [Arguments]    ${ue_id}    ${bearer_id}    ${kbps}    ${protocol}=tcp
    &{body}=        Create Dictionary    protocol=${protocol}    kbps=${kbps}
    ${response}=    POST On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    RETURN    ${response}

Stop Traffic
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    DELETE On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    expected_status=any
    RETURN    ${response}

Get Bearer Traffic
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    GET On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    expected_status=any
    RETURN    ${response}

Get UE State
    [Arguments]    ${ue_id}
    ${response}=    GET On Session    epc    /ues/${ue_id}    expected_status=any
    RETURN    ${response}

Get UE Stats
    [Arguments]    ${ue_id}
    ${params}=      Create Dictionary    ue_id=${ue_id}    include_details=true
    ${response}=    GET On Session    epc    /ues/stats    params=${params}    expected_status=any
    RETURN    ${response}

Status Code Should Be
    [Arguments]    ${response}    ${expected}
    Should Be Equal As Integers    ${response.status_code}    ${expected}

Status Code Should Be Error
    [Arguments]    ${response}
    Should Be True    ${response.status_code} >= 400

*** Test Cases ***
TC01 Sprawdzenie Statystyk Transferu Dla Konkretnego Bearera
    [Documentation]    Można odczytać statystyki transferu dla konkretnego bearera, odpowiedź zawiera tx_bps i rx_bps.
    [Setup]    Setup API Session
    Attach UE    10
    Start Traffic    10    9    500
    ${resp}=    Get Bearer Traffic    10    9
    Status Code Should Be    ${resp}    200
    Dictionary Should Contain Key    ${resp.json()}    tx_bps
    Dictionary Should Contain Key    ${resp.json()}    rx_bps

TC02 Sprawdzenie Sumarycznych Statystyk Transferu Dla UE
    [Documentation]    Można odczytać sumaryczne statystyki transferu dla całego UE przez endpoint /ues/stats.
    [Setup]    Setup API Session
    Attach UE    10
    Start Traffic    10    9    500
    ${resp}=    Get UE Stats    10
    Status Code Should Be    ${resp}    200
    Dictionary Should Contain Key    ${resp.json()}    total_tx_bps
    Dictionary Should Contain Key    ${resp.json()}    total_rx_bps

TC03 Statystyki Transferu Zawieraja Klucz Target Bps
    [Documentation]    Statystyki transferu zawierają klucz target_bps opisujący docelową szybkość.
    [Setup]    Setup API Session
    Attach UE    10
    Start Traffic    10    9    500
    ${resp}=    Get Bearer Traffic    10    9
    Status Code Should Be    ${resp}    200
    Dictionary Should Contain Key    ${resp.json()}    tx_bps
    Dictionary Should Contain Key    ${resp.json()}    rx_bps
    Dictionary Should Contain Key    ${resp.json()}    target_bps

TC04 Po Zatrzymaniu Transferu Bearer Jest Nieaktywny
    [Documentation]    Po zatrzymaniu transferu bearer w stanie UE ma flagę active = False.
    [Setup]    Setup API Session
    Attach UE    10
    Start Traffic    10    9    500
    Stop Traffic    10    9
    ${state}=    Get UE State    10
    Status Code Should Be    ${state}    200
    ${bearer}=    Get From Dictionary    ${state.json()}[bearers]    9
    Should Not Be True    ${bearer}[active]

TC05 Sprawdzenie Statystyk Dla Niepodlaczonego UE Zwraca Blad
    [Documentation]    Próba pobrania statystyk dla UE które nie jest podłączone zwraca błąd.
    [Setup]    Setup API Session
    ${resp}=    Get Bearer Traffic    99    9
    Status Code Should Be Error    ${resp}

TC06 Target Bps Odpowiada Podanej Szybkosci
    [Documentation]    Wartość target_bps w statystykach odpowiada szybkości podanej przy starcie transferu.
    [Setup]    Setup API Session
    Attach UE    10
    Start Traffic    10    9    500
    ${resp}=    Get Bearer Traffic    10    9
    Status Code Should Be    ${resp}    200
    Should Be True    ${resp.json()}[target_bps] > 0
