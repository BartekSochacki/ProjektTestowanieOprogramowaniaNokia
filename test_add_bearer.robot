*** Settings ***
Documentation   Testy funkcjonalności dodawania kanału transportowego (bearer) dla UE w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

*** Variables ***
${BASE_URL}                 http://localhost:8000
${VALID_UE_ID}              10
${VALID_BEARER_ID}          5
${MIN_BEARER_ID}            1
${MAX_BEARER_ID}            8
${ZERO_BEARER_ID}           0
${OUT_OF_RANGE_BEARER_ID}   10
${DEFAULT_BEARER}           9
${NIEPODLACZONY_UE_ID}      99

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

Add Bearer Without ID
    [Arguments]    ${ue_id}
    &{body}=        Create Dictionary
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
TC01 Dodanie Dedykowanego Bearera Dla Podlaczonego UE
    [Documentation]    Można dodać dedykowany bearer dla podłączonego UE, odpowiedź zawiera status i bearer_id.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Add Bearer    ${VALID_UE_ID}    ${VALID_BEARER_ID}
    Status Code Should Be    ${resp}    200
    Should Be Equal    ${resp.json()}[status]    bearer_added
    Should Be Equal As Integers    ${resp.json()}[bearer_id]    ${VALID_BEARER_ID}

TC02 Dodany Bearer Pojawia Sie W Stanie UE
    [Documentation]    Po dodaniu bearer jest widoczny w słowniku bearers w stanie UE.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    Add Bearer    ${VALID_UE_ID}    ${VALID_BEARER_ID}
    ${state}=    Get UE State    ${VALID_UE_ID}
    Status Code Should Be    ${state}    200
    ${bearer_str}=    Convert To String    ${VALID_BEARER_ID}
    Dictionary Should Contain Key    ${state.json()}[bearers]    ${bearer_str}

TC03 Dodanie Bearera Z ID Minimalnym
    [Documentation]    Bearer ID = 1 (dolna granica zakresu 1-8) powinien być akceptowany.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Add Bearer    ${VALID_UE_ID}    ${MIN_BEARER_ID}
    Status Code Should Be    ${resp}    200
    Should Be Equal As Integers    ${resp.json()}[bearer_id]    ${MIN_BEARER_ID}

TC04 Dodanie Bearera Z ID Maksymalnym
    [Documentation]    Bearer ID = 8 (górna granica zakresu, poza domyślnym 9) powinien być akceptowany.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Add Bearer    ${VALID_UE_ID}    ${MAX_BEARER_ID}
    Status Code Should Be    ${resp}    200
    Should Be Equal As Integers    ${resp.json()}[bearer_id]    ${MAX_BEARER_ID}

TC05 Bearer ID Zero Zwraca Blad
    [Documentation]    Bearer ID = 0 jest poza zakresem (1-9), powinien zwrócić 422.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Add Bearer    ${VALID_UE_ID}    ${ZERO_BEARER_ID}
    Status Code Should Be    ${resp}    422

TC06 Bearer ID Powyzej Zakresu Zwraca Blad
    [Documentation]    Bearer ID = 10 jest poza zakresem (1-9), powinien zwrócić 422.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Add Bearer    ${VALID_UE_ID}    ${OUT_OF_RANGE_BEARER_ID}
    Status Code Should Be    ${resp}    422

TC07 Dodanie Istniejacego Bearera Zwraca Blad
    [Documentation]    Ponowne dodanie tego samego bearer ID zwraca błąd 400.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    Add Bearer    ${VALID_UE_ID}    ${VALID_BEARER_ID}
    ${second}=    Add Bearer    ${VALID_UE_ID}    ${VALID_BEARER_ID}
    Status Code Should Be    ${second}    400
    Should Be Equal    ${second.json()}[detail]    Bearer already exists

TC08 Dodanie Domyslnego Bearera 9 Zwraca Blad
    [Documentation]    Bearer 9 jest przydzielany automatycznie przy attach, ponowne dodanie zwraca błąd 400.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Add Bearer    ${VALID_UE_ID}    ${DEFAULT_BEARER}
    Status Code Should Be    ${resp}    400
    Should Be Equal    ${resp.json()}[detail]    Bearer already exists

TC09 Dodanie Bearera Bez Podania ID Zwraca Blad
    [Documentation]    Żądanie bez bearer ID powinno zwrócić błąd 422.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Add Bearer Without ID    ${VALID_UE_ID}
    Status Code Should Be    ${resp}    422

TC10 Dodanie Bearera Dla Niepodlaczonego UE Zwraca Blad
    [Documentation]    Próba dodania bearera dla UE które nie jest podłączone zwraca błąd 400.
    [Setup]    Setup API Session
    ${resp}=    Add Bearer    ${NIEPODLACZONY_UE_ID}    ${VALID_BEARER_ID}
    Status Code Should Be    ${resp}    400
    Should Be Equal    ${resp.json()}[detail]    UE not found
