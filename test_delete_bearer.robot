*** Settings ***
Documentation   Testy funkcjonalności usuwania kanału transportowego (bearer) z UE w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

*** Variables ***
${BASE_URL}                 http://localhost:8000

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

Delete Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    DELETE On Session    epc    /ues/${ue_id}/bearers/${bearer_id}    expected_status=any
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
TC01 Usuniecie Dedykowanego Bearera Z UE
    [Documentation]    Można usunąć dedykowany bearer z podłączonego UE.
    [Setup]    Setup API Session
    Attach UE    10
    Add Bearer    10    5
    ${resp}=    Delete Bearer    10    5
    Status Code Should Be    ${resp}    200

TC02 Po Usunieciu Bearer Znika Ze Stanu UE
    [Documentation]    Po usunięciu bearer nie jest już widoczny w słowniku bearers UE.
    [Setup]    Setup API Session
    Attach UE    10
    Add Bearer    10    5
    Delete Bearer    10    5
    ${state}=    Get UE State    10
    Status Code Should Be    ${state}    200
    Dictionary Should Not Contain Key    ${state.json()}[bearers]    5

TC03 Usuniecie Bearera O ID Spoza Zakresu Zwraca Blad
    [Documentation]    Bearer ID = 10 jest poza zakresem (1-9), usunięcie powinno zwrócić błąd.
    [Setup]    Setup API Session
    Attach UE    10
    ${resp}=    Delete Bearer    10    10
    Status Code Should Be Error    ${resp}

TC04 Usuniecie Nieaktywnego Bearera Zwraca Blad
    [Documentation]    Próba usunięcia bearera który nie jest aktywny (nie został dodany) zwraca błąd.
    [Setup]    Setup API Session
    Attach UE    10
    ${resp}=    Delete Bearer    10    7
    Status Code Should Be Error    ${resp}

TC05 Usuniecie Domyslnego Bearera 9 Zwraca Blad
    [Documentation]    Domyślny bearer ID=9 nie może zostać usunięty.
    [Setup]    Setup API Session
    Attach UE    10
    ${resp}=    Delete Bearer    10    9
    Status Code Should Be Error    ${resp}

TC06 Usuniecie Bearera Bez UE ID Zwraca Blad
    [Documentation]    Żądanie bez UE ID w URL powinno zwrócić błąd.
    [Setup]    Setup API Session
    ${resp}=    Delete Bearer    ${EMPTY}    5
    Status Code Should Be Error    ${resp}

TC07 Usuniecie Bearera Z ID Zero Zwraca Blad
    [Documentation]    Bearer ID = 0 jest poza zakresem (1-9), powinien zwrócić błąd.
    [Setup]    Setup API Session
    Attach UE    10
    ${resp}=    Delete Bearer    10    0
    Status Code Should Be Error    ${resp}

TC08 Usuniecie Bearera Dla Niepodlaczonego UE Zwraca Blad
    [Documentation]    Próba usunięcia bearera dla UE które nie jest podłączone zwraca błąd.
    [Setup]    Setup API Session
    ${resp}=    Delete Bearer    10    5
    Status Code Should Be Error    ${resp}
