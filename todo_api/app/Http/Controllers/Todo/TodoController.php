<?php

namespace App\Http\Controllers\Todo;

use App\Http\Controllers\Controller;
use App\Models\Todo;
use Illuminate\Http\Request;

class TodoController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $todos = auth()->user()->todos()->latest()->get();
        return response([
            'todos' => $todos
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:255'],
        ]);

        $todo = auth()->user()->todos()->create($validated);

        return response([
            'todo' => $todo
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Todo $todo)
    {
        if ($todo->user_id != auth()->user()->id) {
            return response([
                'message' => 'This todo does not belong to you'
            ], 403);
        }

        return response([
            'todo' => $todo
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Todo $todo)
    {

        if ($todo->user_id != auth()->user()->id) {
            return response([
                'message' => 'This todo does not belong to you'
            ], 403);
        }

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:255'],
        ]);

        $todo->update($validated);
        return response([
            'todo' => $todo
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Todo $todo)
    {
        if ($todo->user_id != auth()->user()->id) {
            return response([
                'message' => 'This todo does not belong to you'
            ], 403);
        }

        $todo->delete();
        return response([
            'message' => 'Todo deleted successfully'
        ]);
    }
}
