<?php

use App\Models\sms;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::get('/sms', function (Request $request) {
    if(null !== $request->input('queue')){
        $smss = sms::where(function ($query) {
            $query->where('status', '=', 0)
                  ->orWhere('status', '=', 1);
        })->orderBy('created_at', 'ASC')->get();
    }else{
        $smss = sms::orderBy('created_at', 'ASC')->get();
    }
    $ids = array();
    foreach ($smss as $sm) {
        array_push($ids,$sm->id);
    }

    //return as text
    if(null !== $request->input('asText')){
        foreach ($ids as $id) {
            echo($id.',');
        }
        return;
    }

    //return as json
    return $ids;
});


Route::get('/getSMS/{id}', function (Request $request, int $id) {
    $sm = sms::find($id);
    //return as text
    if(null !== $request->input('asText')){
        echo($sm->number.','.$sm->content);
        return;
    }
    //return as json
    return $sm; 
});

Route::get('/procSMS/{id}', function (Request $request, int $id) {
    $sm = sms::find($id);
    $sm->status = 1;
    $sm->save();
    //return as text
    if(null !== $request->input('asText')){
        echo '1';
        return;
    }
    //return as json
    return $sm;
});

Route::get('/setSuccess/{id}', function (Request $request, int $id) {
    $sm = sms::find($id);
    $sm->status = 2;
    $sm->save();
    //return as text
    if(null !== $request->input('asText')){
        echo '1';
        return;
    }
    //return as json
    return $sm;
});

Route::get('/setFailed/{id}', function (Request $request, int $id) {
    $sm = sms::find($id);
    $sm->status = -1;
    $sm->save();
    //return as text
    if(null !== $request->input('asText')){
        echo '1';
        return;
    }
    //return as json
    return $sm;
});

Route::post('/createSMS', function (Request $request) { 
    $sms = new sms;
    $sms->number = $request->input('number');
    $sms->content = $request->input('content');
    $sms->save();
    return $sms;
});


