*** Settings ***
Documentation   Testy funkcjonalności sprawdzania listy bearerów UE w symulatorze EPC.
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

Add Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    &{body}=        Create Dictionary    bearer_id=${bearer_id}
    ${response}=    POST On Session    epc    /ues/${ue_id}/bearers    json=${body}    expected_status=any
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
TC01 Sprawdzenie Listy Bearerow Dla Podlaczonego UE
    [Documentation]    Można odczytać listę bearerów dla podłączonego UE, lista nie jest pusta.
    [Setup]    Setup API Session
    Attach UE    10
    ${state}=    Get UE State    10
    Status Code Should Be    ${state}    200
    Dictionary Should Contain Key    ${state.json()}    bearers
    ${bearers}=    Get Dictionary Keys    ${state.json()}[bearers]
    Should Not Be Empty    ${bearers}

TC02 Sprawdzenie Bearerow Po Dodaniu Dodatkowego Bearera
    [Documentation]    Po dodaniu nowego bearera lista zawiera zarówno bearer domyślny jak i nowy.
    [Setup]    Setup API Session
    Attach UE    10
    Add Bearer    10    3
    ${state}=    Get UE State    10
    Status Code Should Be    ${state}    200
    Dictionary Should Contain Key    ${state.json()}[bearers]    9
    Dictionary Should Contain Key    ${state.json()}[bearers]    3

TC03 Nowe UE Ma Dokladnie Jeden Bearer Domyslny
    [Documentation]    Po podłączeniu UE ma dokładnie jeden bearer (domyślny ID=9).
    [Setup]    Setup API Session
    Attach UE    10
    ${state}=    Get UE State    10
    Status Code Should Be    ${state}    200
    ${bearers}=    Get Dictionary Keys    ${state.json()}[bearers]
    Length Should Be    ${bearers}    1
    Dictionary Should Contain Key    ${state.json()}[bearers]    9

TC04 Bearer Ma Klucz Active W Strukturze
    [Documentation]    Każdy bearer w stanie UE zawiera klucz active opisujący jego aktywność.
    [Setup]    Setup API Session
    Attach UE    10
    ${state}=    Get UE State    10
    Status Code Should Be    ${state}    200
    ${bearer}=    Get From Dictionary    ${state.json()}[bearers]    9
    Dictionary Should Contain Key    ${bearer}    active

TC05 Sprawdzenie Bearerow Dla Niepodlaczonego UE Zwraca Blad
    [Documentation]    Próba pobrania stanu UE które nie jest podłączone zwraca błąd.
    [Setup]    Setup API Session
    ${state}=    Get UE State    99
    Status Code Should Be Error    ${state}

TC06 Liczba Bearerow Rosnie Po Dodaniu Nowych
    [Documentation]    Liczba bearerów w stanie UE rośnie po każdym dodaniu nowego bearera.
    [Setup]    Setup API Session
    Attach UE    10
    ${state_before}=    Get UE State    10
    ${count_before}=    Get Length    ${state_before.json()}[bearers]
    Add Bearer    10    3
    ${state_after}=    Get UE State    10
    ${count_after}=    Get Length    ${state_after.json()}[bearers]
    Should Be True    ${count_after} > ${count_before}
